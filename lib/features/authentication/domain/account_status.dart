enum AccountStatus {
  unauthenticated,
  emailUnverified,
  registrationIncomplete,
  verificationNotSubmitted,
  verificationPending,
  verificationApproved,
  verificationRejected,
  suspended,
  deactivated,
  deletionScheduled;

  bool get isApproved => this == AccountStatus.verificationApproved;
  bool get isPendingReview => this == AccountStatus.verificationPending;
  bool get isRejected => this == AccountStatus.verificationRejected;
  bool get isSuspended => this == AccountStatus.suspended;
  bool get isDeactivated => this == AccountStatus.deactivated || this == AccountStatus.deletionScheduled;
}
