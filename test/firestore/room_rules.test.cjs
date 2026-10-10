const {before, beforeEach, after, test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc, collection, query, where, getDocs, serverTimestamp, Timestamp, runTransaction, writeBatch} = require('firebase/firestore');
let env;
const room = {capacity: 1, priceInCentimes: 1500000, totalRooms: 5};
const hotel = (id, status = 'draft', rooms = {}) => ({
  id, ownerId: 'owner', name: 'TALA Hotel', description: 'A hotel\nnear the sea.',
  wilaya: 'Alger', address: 'Alger centre', phoneNumber: '0550123456',
  images: ['https://res.cloudinary.com/example/image/upload/hotel.jpg'],
  mapUrl: 'https://maps.app.goo.gl/example', status,
  createdAt: Timestamp.fromMillis(1000), updatedAt: Timestamp.fromMillis(1000),
  reviewedAt: null, reviewedBy: null, rejectionReason: null, rooms,
});
const db = (uid, verified = true) => env.authenticatedContext(uid, {email_verified: verified, email: uid + '@example.com'}).firestore();
const change = (database, id, fields) => updateDoc(doc(database, 'hotels', id), {...fields, updatedAt: serverTimestamp()});

before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-tala-trip', firestore: {
    host: '127.0.0.1', port: 8080,
    rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
  }});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    await Promise.all([
      ...[['owner','hotelOwner'], ['other','hotelOwner'], ['traveler','traveler'], ['admin','admin']]
        .map(([id, role]) => setDoc(doc(database, 'users', id), {id, role})),
      setDoc(doc(database, 'hotels', 'draft'), hotel('draft')),
      setDoc(doc(database, 'hotels', 'pending'), hotel('pending', 'pending', {single: room})),
      setDoc(doc(database, 'hotels', 'approved'), hotel('approved', 'approved', {single: room})),
      setDoc(doc(database, 'hotels', 'rejected'), {...hotel('rejected', 'rejected'), rejectionReason: 'Add rooms', reviewedBy: 'admin', reviewedAt: Timestamp.fromMillis(1000)}),
    ]);
  });
});
after(async () => { if (env) await env.cleanup(); });

test('owner adds valid room inventory and updates approved prices', async () => {
  await assertSucceeds(change(db('owner'), 'draft', {rooms: {single: room}}));
  await assertSucceeds(change(db('owner'), 'approved', {rooms: {single: {...room, priceInCentimes: 2500000}}}));
});
test('other owners, travelers and admins cannot change room inventory', async () => {
  for (const uid of ['other', 'traveler', 'admin']) {
    await assertFails(change(db(uid), 'approved', {rooms: {single: room}}));
  }
});
test('room mutations cannot change ownership or review metadata', async () => {
  await assertFails(change(db('owner'), 'approved', {rooms: {}, ownerId: 'other'}));
  await assertFails(change(db('owner'), 'approved', {rooms: {}, reviewedBy: 'owner'}));
  await assertFails(change(db('owner'), 'approved', {rooms: {}, status: 'draft'}));
});
test('pending room inventory is immutable even for the owner', async () => {
  await assertFails(change(db('owner'), 'pending', {rooms: {}}));
});
test('invalid capacities, prices, counts and extra room types fail', async () => {
  for (const rooms of [
    {single: {...room, capacity: 2}}, {double: {...room, capacity: 1}},
    {suite: {...room, capacity: 0}}, {suite: {...room, capacity: 21}},
    {single: {...room, priceInCentimes: 0}}, {single: {...room, priceInCentimes: -1}},
    {single: {...room, priceInCentimes: 1.5}}, {single: {...room, totalRooms: 0}},
    {single: {...room, totalRooms: 1.5}}, {triple: room}, {single: {...room, ownerId:'owner'}},
  ]) await assertFails(change(db('owner'), 'draft', {rooms}));
});
test('Double and Suite capacities accept the intended values', async () => {
  await assertSucceeds(change(db('owner'), 'draft', {rooms: {
    double: {...room, capacity: 2}, suite: {...room, capacity: 4},
  }}));
});
test('submission needs rooms and complete valid details', async () => {
  await assertFails(change(db('owner'), 'draft', {status: 'pending'}));
  await assertSucceeds(change(db('owner'), 'draft', {rooms: {single: room}}));
  await assertSucceeds(change(db('owner'), 'draft', {status: 'pending'}));
  await assertFails(change(db('owner'), 'pending', {status: 'approved'}));
});
test('admin review is restricted to pending and requires valid metadata', async () => {
  await assertSucceeds(change(db('admin'), 'pending', {status: 'approved', reviewedBy: 'admin', reviewedAt: serverTimestamp()}));
  await assertFails(change(db('admin'), 'draft', {status: 'approved', reviewedBy: 'admin', reviewedAt: serverTimestamp()}));
});
test('rejection needs a reason; room edits reset rejection metadata', async () => {
  await assertFails(change(db('admin'), 'pending', {status: 'rejected', reviewedBy: 'admin', reviewedAt: serverTimestamp(), rejectionReason: '  '}));
  await assertSucceeds(change(db('admin'), 'pending', {status: 'rejected', reviewedBy: 'admin', reviewedAt: serverTimestamp(), rejectionReason: 'Fix details'}));
  await assertFails(change(db('owner'), 'rejected', {rooms: {single: room}}));
  await assertSucceeds(change(db('owner'), 'rejected', {rooms: {single: room}, status: 'draft', reviewedBy: null, reviewedAt: null, rejectionReason: null}));
});
test('traveler reads approved hotels only; discovery query succeeds', async () => {
  await assertSucceeds(getDoc(doc(db('traveler'), 'hotels', 'approved')));
  await assertFails(getDoc(doc(db('traveler'), 'hotels', 'draft')));
  await assertSucceeds(getDocs(query(collection(db('traveler'), 'hotels'), where('status', '==', 'approved'))));
  await assertFails(getDocs(collection(db('traveler'), 'hotels')));
  await assertSucceeds(getDocs(query(collection(db('owner'), 'hotels'), where('ownerId', '==', 'owner'))));
});
test('signed-out and unverified users cannot read hotel data', async () => {
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'hotels', 'approved')));
  await assertFails(getDoc(doc(db('traveler', false), 'hotels', 'approved')));
});
test('only owner deletes own drafts; embedded rooms vanish with the hotel', async () => {
  await assertSucceeds(change(db('owner'), 'draft', {rooms: {single: room}}));
  await assertFails(deleteDoc(doc(db('other'), 'hotels', 'draft')));
  await assertFails(deleteDoc(doc(db('owner'), 'hotels', 'approved')));
  await assertSucceeds(deleteDoc(doc(db('owner'), 'hotels', 'draft')));
  await env.withSecurityRulesDisabled(async (context) => {
    assert.equal((await getDoc(doc(context.firestore(), 'hotels', 'draft'))).exists(), false);
  });
});
test('legacy hotels without rooms remain readable and can receive rooms', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    const legacy = hotel('legacy', 'approved'); delete legacy.rooms;
    await setDoc(doc(context.firestore(), 'hotels', 'legacy'), legacy);
  });
  await assertSucceeds(getDoc(doc(db('traveler'), 'hotels', 'legacy')));
  await assertSucceeds(change(db('owner'), 'legacy', {rooms: {single: room}}));
});
test('invalid hotel fields and forged admin registration fail', async () => {
  for (const fields of [{wilaya:'Paris'}, {phoneNumber:'123'}, {images:['file:///photo.jpg']},
    {mapUrl:'https://maps.app.goo.gl.evil.com/a'}, {mapUrl:'javascript:alert(1)'},
    {images:Array(11).fill('https://res.cloudinary.com/a.jpg')}, {name:'   '}]) {
    await assertFails(change(db('owner'), 'draft', fields));
  }
  await assertFails(setDoc(doc(db('newUser'), 'users', 'newUser'), {id:'newUser',role:'admin'}));
  await assertFails(updateDoc(doc(db('owner'), 'users', 'owner'), {role:'admin'}));
});
test('valid incomplete draft creation remains supported', async () => {
  const draft = {...hotel('new'), description:'', wilaya:'', address:'', phoneNumber:'', images:[], mapUrl:null};
  await assertSucceeds(setDoc(doc(db('owner'), 'hotels', 'new'), draft));
  await assertFails(setDoc(doc(db('traveler'), 'hotels', 'travelerHotel'), {...draft, id:'travelerHotel', ownerId:'traveler'}));
});
test('maximum room categories and photos fit the rule evaluation budget', async () => {
  const rooms = {single: room, double: {...room, capacity: 2}, suite: {...room, capacity: 20}};
  const full = {...hotel('full'), rooms, images: Array(10).fill(hotel('full').images[0])};
  await assertSucceeds(setDoc(doc(db('owner'), 'hotels', 'full'), full));
  await assertSucceeds(change(db('owner'), 'full', {status: 'pending'}));
  await assertSucceeds(change(db('admin'), 'full', {status: 'approved', reviewedBy: 'admin', reviewedAt: serverTimestamp()}));
});
test('legacy invalid metadata does not block room maintenance or rejection', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'hotels', 'old-approved'), {...hotel('old-approved', 'approved'), phoneNumber: 'old phone format'});
    await setDoc(doc(context.firestore(), 'hotels', 'old-pending'), {...hotel('old-pending', 'pending'), mapUrl: 'http://old.example'});
  });
  await assertSucceeds(change(db('owner'), 'old-approved', {rooms: {single: room}}));
  await assertSucceeds(change(db('admin'), 'old-pending', {status: 'rejected', reviewedBy: 'admin', reviewedAt: serverTimestamp(), rejectionReason: 'Please update the map link.'}));
});
test('unchanged approved room save and normalized international phone succeed', async () => {
  await assertSucceeds(change(db('owner'), 'approved', {rooms: {single: room}}));
  await assertSucceeds(change(db('owner'), 'draft', {phoneNumber: '+213550123456', mapUrl: 'https://www.google.com/maps?q=Alger'}));
});

// Registration can resume profile creation before email verification.
test('missing profile setup can resume; repeated setup preserves the saved role', async () => {
  const database = db('recovering', false);
  const reference = doc(database, 'users', 'recovering');
  const profile = {id: 'recovering', username: 'Original', email: 'recovering@example.com', mobileNumber: '+33612345678', role: 'traveler'};
  async function finish(details) {
    return runTransaction(database, async transaction => {
      const snapshot = await transaction.get(reference);
      if (snapshot.exists()) return snapshot.data();
      transaction.set(reference, details);
      return details;
    });
  }
  await assertSucceeds(finish(profile));
  const recovered = await assertSucceeds(finish({...profile, username: 'Changed', role: 'hotelOwner'}));
  assert.equal(recovered.role, 'traveler');
  assert.equal(recovered.username, 'Original');
  await assertFails(updateDoc(reference, {role: 'hotelOwner'}));
});

test('profile setup cannot create another account profile or mismatched email', async () => {
  const profile = {id: 'recovering', username: 'Traveler', email: 'recovering@example.com', mobileNumber: '+447911123456', role: 'traveler'};
  await assertFails(setDoc(doc(db('other'), 'users', 'recovering'), profile));
  await assertFails(setDoc(doc(db('recovering'), 'users', 'recovering'), {...profile, email: 'other@example.com'}));
});

test('international traveler phone can be snapshotted in a booking', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'users', 'traveler'), {
      id: 'traveler', username: 'Traveler', email: 'traveler@example.com', mobileNumber: '+33612345678', role: 'traveler',
    });
  });
  const database = db('traveler');
  const requestId = 'a'.repeat(32);
  const start = Math.floor(Date.now() / 86400000) * 86400000 + 3 * 86400000;
  const booking = {
    id: requestId, requestId, travelerId: 'traveler', ownerId: 'owner', hotelId: 'approved',
    travelerName: 'Traveler', travelerPhone: '+33612345678', hotelName: 'TALA Hotel',
    hotelAddress: 'Alger centre', hotelPhone: '0550123456', roomType: 'single', capacityAtBooking: 1, guests: 1,
    checkInDate: Timestamp.fromMillis(start), checkOutDate: Timestamp.fromMillis(start + 86400000),
    checkInStartsAt: Timestamp.fromMillis(start - 3600000),
    nightlyPriceInCentimes: room.priceInCentimes, totalPriceInCentimes: room.priceInCentimes,
    currency: 'DZD', status: 'pending', createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    decidedAt: null, decidedBy: null, rejectionReason: null, cancelledAt: null, cancelledBy: null,
  };
  const batch = writeBatch(database);
  batch.set(doc(database, 'bookings', requestId), booking);
  batch.set(doc(database, 'users', 'traveler', 'bookingRequests', requestId), {
    requestId, travelerId: 'traveler', bookingId: requestId, status: 'recorded', createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(database, 'bookings', requestId))).data().travelerPhone, '+33612345678');
});
