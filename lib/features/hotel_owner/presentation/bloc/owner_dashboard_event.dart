abstract class OwnerDashboardEvent {
  const OwnerDashboardEvent();
}

// Used for initial loading, Retry, and pull-to-refresh.
class OwnerDashboardRequested extends OwnerDashboardEvent {
  const OwnerDashboardRequested();
}
