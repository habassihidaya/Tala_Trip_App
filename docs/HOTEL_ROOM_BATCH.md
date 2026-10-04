# Hotel and room management batch

Base: `92c7fe5` — Fix hotel creation and Cloudinary photo uploads.

## Before this batch

The repository already had Firebase/Cloudinary hotel draft creation, editing, deletion,
submission and admin review, with BLoCs, repositories, use cases, DI, and route guards.
The traveler screen was a placeholder; room code did not exist. The current source offers
traveler/hotelOwner account selection at signup. This batch preserves that flow;
it does not introduce the older handover's owner-application approval flow.

## What changed

- Added a complete `features/rooms` data/domain/presentation feature using BLoC,
  get_it, Firestore transactions, and `Either<Failure, ...>`.
- Owners add, edit and remove Single, Double and Suite inventory. Admins and travelers
  can inspect room types and prices, subject to hotel visibility rules.
- Connected traveler discovery to approved hotels, hotel details, room prices and
  external Google Maps links. Loading, empty, error and retry states are included.
- Added validation before uploads and backend validation in Firestore rules.
- Hotel/room reads request server data. Draft creation uses a transaction with a
  profile read, so an offline write is not silently queued while the form waits.
- A pending hotel locks room changes. Room edits to a rejected hotel return it to
  draft and clear review metadata. Approved hotels allow price/inventory maintenance.
- A hotel needs at least one room type before submission/approval.
- Draft hotel deletion removes embedded inventory atomically. Cloudinary assets are
  not deleted by Flutter; deleting a hotel does not imply Cloudinary cleanup.
- Hotel edits reject a stale updatedAt; room edits/deletions compare the original
  category with the current category inside a transaction. A conflicting edit asks
  the user to reload rather than silently overwriting the newer value.
- Successful photo URLs are cached for retries while the form's BLoC remains open.
  Leaving the form loses that cache. Cloudinary upload and Firestore persistence
  remain separate operations; unused uploaded assets may still remain.
- Added Android release internet permission and an iOS photo-library explanation.

## V1 choices made for the new room feature

Each hotel has at most one inventory entry per room type. A category describes the
price, capacity and count of interchangeable rooms; it is not a numbered physical room.
Single holds 1 guest, Double holds 2, Suite has a configurable capacity.
The form and rules use matching upper validation limits: Suite capacity 20 guests,
10,000 rooms per category, and 1,000,000 DZD per room per night. These are new input
limits for this implementation, not requirements recovered from the handover.

Prices accept at most two decimal places and are stored in integer centimes:
`1500.50 DZD -> 150050`. This avoids floating-point rounding when booking totals
are introduced. There is no payment processing.

Inventory count is NOT date availability. Booking is deliberately not implemented.
When adding booking, reserve inventory transactionally by date, validate guest counts
against capacity, prevent overbooking, snapshot the price and room description,
and guard inventory reductions/removals when future bookings reference them.

## Data and compatibility

Existing hotels without `rooms` are treated as having no room categories. No bulk
migration or production data write is needed. Adding the first type creates the map.
Approved legacy hotels remain readable. Room-only maintenance preserves their old
metadata; stricter hotel validation applies when saving hotel details or submitting.
A legacy pending listing without rooms must be rejected, completed, and resubmitted.

Example Firestore field on `hotels/{hotelId}`:

```json
{
  "rooms": {
    "single": {"capacity": 1, "priceInCentimes": 700000, "totalRooms": 8},
    "double": {"capacity": 2, "priceInCentimes": 1000000, "totalRooms": 12},
    "suite": {"capacity": 4, "priceInCentimes": 1800000, "totalRooms": 2}
  }
}
```

No room subcollection or composite Firestore index is required. The hotel lists
continue using single equality filters and local sorting. Normal default single-field
indexing must remain enabled for hotel ownerId/status.

## Apply

Use the changed-files ZIP at the root of your existing project, preserving its paths,
or apply the supplied Git patch on the base commit. The package contains complete
replacement files, not partial snippets. Do not overwrite unrelated local changes.

From the project root:

```sh
flutter pub get
flutter analyze
flutter test
```

The new dependency is `url_launcher`. Rebuild/restart the app after fetching it.
Publish the included `firestore.rules` in Firebase Console, or use your authenticated
Firebase CLI with the intended project ID:

```sh
firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
```

The checked-in `firebase.json` now points at the rules file. No rules or data were
deployed to your Firebase project by this batch. The application still uses your
existing Firebase configuration and Cloudinary unsigned preset.

## Automated verification

See the final verification section below for actual executed results. The repository
includes tests for exact money parsing, capacities, map-link validation, phone
normalization, BLoC failure/retry, and Firestore permissions/transitions.

To run security tests independently, use Node 22+ and Java 21+:

```sh
cd test/firestore
npm install
npm test
```

These use only the local emulator and `demo-tala-trip`, not production Firebase.
The temporary Java runtime for these tests does not change your Flutter Android JDK.

## Manual checks still needed on your device

1. Sign in as an owner. Create a hotel with a phone photo, reopen it, edit its details,
   add/remove photos, and confirm the owner list refreshes. Open its Google Maps link.
2. Add Single, Double and Suite. Confirm fixed Single/Double capacities, editable Suite
   capacity, exact decimal prices, edit/remove actions, persistence after reopening,
   and no duplicate category. Try zero/negative prices and non-integer counts.
3. Submit with missing details or no rooms: show a useful message. Complete it and
   submit successfully. Confirm pending room controls are read-only.
4. As admin, inspect rooms, reject with a reason, then have the owner edit rooms and
   resubmit. Approve it and verify it appears for a traveler with the expected prices.
5. As another owner, try the first owner's hotel route. Backend must reject private
   reads and all mutations. Travelers must never see draft/pending/rejected listings.
6. Edit the same category on two devices: after one saves, the stale save must fail
   with reload guidance. Repeat for hotel details.
7. Disconnect during upload/save. Confirm no false success, useful feedback, retained
   form values, and a working retry. Confirm repeated taps don't create duplicate room types.
8. Delete a disposable draft containing rooms; ensure the hotel is gone. Check back
   navigation, sign-out, and startup session restoration for regressions.

Full emulator/device UI testing and live Cloudinary/Firebase integration remain manual.

## Executed verification results

- `flutter pub get`: succeeded using Flutter 3.44.8 / Dart 3.12.2; lockfile updated
  with url_launcher and its platform packages. Generated desktop plugin registrants
  are included because dependency resolution updates these tracked files.
- `flutter test --no-pub`: 8 tests passed (money/capacity/map/phone validation,
  BLoC save failure and retry, mocked Cloudinary success/unsafe URL/missing file).
- Firestore emulator: 18 tests passed, including owner isolation, invalid room
  data, pending locks, approval/rejection, legacy records, draft deletion, read
  restrictions, role escalation attempts, and the maximum 3-type/10-photo listing.
- `flutter analyze --no-pub`: passed with no issues.
- `git diff --check`: passed.
- Live Firebase/Cloudinary operations, phone navigation, maps launching and iOS/Android
  builds were not executed. The attached photo opened successfully locally; it was
  not uploaded to a service or added as hardcoded application data.
