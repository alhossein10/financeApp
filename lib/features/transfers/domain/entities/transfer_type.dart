/// Enum representing the type of transfer for filtering purposes
/// 
/// Used by SuperAdmin to filter transfers by direction:
/// - incoming: Transfers received by the user
/// - outgoing: Transfers sent by the user
/// - all: All transfers (no filtering)
/// 
/// Requirements: 2.3, 2.4
enum TransferType {
  /// Transfers received by the user
  incoming,
  
  /// Transfers sent by the user
  outgoing,
  
  /// All transfers (no filtering)
  all,
}
