/**
 * Module     : DRC202Types.mo
 * CanisterId : bffvb-aiaaa-aaaak-ae3ba-cai
 * Test       : bcetv-nqaaa-aaaak-ae3bq-cai
 */
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Time "mo:base/Time";
import Binary "Binary";
import SHA224 "mo:sha224/SHA224";
import Buffer "mo:base/Buffer";

module {
  public type Address = Text;
  public type AccountId = Blob;
  public type Time = Time.Time;
  public type Txid = Blob;
  public type Token = Principal;
  public type BucketId = Principal;
  public type Gas = { #token : Nat; #cycles : Nat; #noFee };
  public type Operation = {
    #approve : { allowance : Nat };
    #lockTransfer : { locked : Nat; expiration : Time; decider : AccountId };
    #transfer : { action : { #burn; #mint; #send } };
    #executeTransfer : { fallback : Nat; lockedTxid : Txid };
  };
  public type Transaction = {
    to : AccountId;
    value : Nat;
    data : ?Blob;
    from : AccountId;
    operation : Operation;
  };
  public type TxnRecord = {
    gas : Gas;
    transaction : Transaction;
    txid : Txid;
    nonce : Nat;
    timestamp : Time;
    msgCaller : ?Principal;
    caller : AccountId;
    index : Nat;
  };
  public type Setting = {
      EN_DEBUG: Bool;
      MAX_CACHE_TIME: Nat;
      MAX_CACHE_NUMBER_PER: Nat;
      MAX_STORAGE_TRIES: Nat;
  };
  public type Config = {
      EN_DEBUG: ?Bool;
      MAX_CACHE_TIME: ?Nat;
      MAX_CACHE_NUMBER_PER: ?Nat;
      MAX_STORAGE_TRIES: ?Nat;
  };
  public type Root = actor {
    proxyList : shared query () -> async {root: Principal; list: [(Principal, Time.Time, Nat)]; current: ?(Principal, Time.Time, Nat)};
    getTxnHash : shared composite query (_token: Token, _txid: Txid) -> async [Text]; // Hex
    getArchivedTxnBytes : shared composite query (_token: Token, _txid: Txid) -> async [([Nat8], Time.Time)];
    getArchivedTxn : shared composite query (_token: Token, _txid: Txid) -> async [(TxnRecord, Time.Time)];
    getArchivedTxnByIndex : shared composite query (_token: Token, _tokenBlockIndex: Nat) -> async [(TxnRecord, Time.Time)];
    getArchivedTokenTxns : shared composite query (_token: Token, _start_desc: Nat, _length: Nat) -> async [TxnRecord];
    getArchivedAccountTxns : shared composite query (_buckets_offset: ?Nat, _buckets_length: Nat, _account: AccountId, _token: ?Token, _page: ?Nat32/*base 1*/, _size: ?Nat32) -> async 
    {data: [(Principal, [(TxnRecord, Time.Time)])]; totalPage: Nat; total: Nat};
  };
  public type Self = actor {
    version: shared query () -> async Nat8;
    fee : shared query () -> async (cycles: Nat); //cycles
    setStd : shared (Text) -> async (); 
    // store : shared (_txn: TxnRecord) -> async (); // @deprecated: This method will be deprecated
    storeBatch : shared (_txns: [TxnRecord]) -> async (); 
    storeBytesBatch: shared (_txns: [(_txid: Txid, _data: [Nat8])]) -> async (); 
    // bucket : shared query (_token: Principal, _txid: Txid, _step: Nat, _version: ?Nat8) -> async (bucket: ?BucketId); // @deprecated: This method will be deprecated
    // bucketByIndex : shared query (_token: Token, _blockIndex: Nat, _step: Nat, _version: ?Nat8) -> async (bucket: ?BucketId); // @deprecated: This method will be deprecated
    location : shared query (_token: Token, _arg: {#txid: Txid; #index: Nat; #account: AccountId}, _version: ?Nat8) -> async [BucketId];
    bucketListSorted : shared query () -> async [(BucketId, Time.Time, Nat)];
  };
  public type Proxy = Self;
  public type Bucket = actor {
    txnBytes: shared query (_token: Token, _txid: Txid) -> async ?([Nat8], Time.Time);
    txnBytesHistory: shared query (_token: Token, _txid: Txid) -> async [([Nat8], Time.Time)];
    txn: shared query (_token: Token, _txid: Txid) -> async ?(TxnRecord, Time.Time);
    txnHistory: shared query (_token: Token, _txid: Txid) -> async [(TxnRecord, Time.Time)];
    txnByIndex: shared query (_token: Token, _blockIndex: Nat) -> async [(TxnRecord, Time.Time)];
    txnByAccountId: shared query (_accountId: AccountId, _token: ?Token, _page: ?Nat32/*base 1*/, _size: ?Nat32) -> async 
    {data: [(Token, [(TxnRecord, Time.Time)])]; totalPage: Nat; total: Nat};
    txnHash: shared query (_token: Token, _txid: Txid) -> async [Text];
    // txnBytesHash: shared query (_token: Token, _txid: Txid, _index: Nat) -> async ?Text;
  };
  public type Impl = actor {
    drc202_getConfig : shared query () -> async Setting;
    drc202_canisterId : shared query () -> async Principal;
    drc202_events : shared query (_account: ?Address) -> async [TxnRecord];
    drc202_events_filter : shared query (_account: ?Address, _startTime: ?Time.Time, _endTime: ?Time.Time) -> async ([TxnRecord], Bool);
    drc202_txn : shared query (_txid: Txid) -> async (txn: ?TxnRecord);
    // drc202_txn2 : shared composite query (_txid: Txid) -> async (txn: ?TxnRecord); // OPTIONAL
    // drc202_archived_txns : shared composite query (_start_desc: Nat, _length: Nat) -> async [TxnRecord];
    // drc202_archived_account_txns : shared composite query (_buckets_offset: ?Nat, _buckets_length: Nat, _account: AccountId, _token: ?Token, _page: ?Nat32/*base 1*/, _size: ?Nat32) -> async 
    // {data: [(Principal, [(TxnRecord, Time.Time)])]; totalPage: Nat; total: Nat};
  };
  public func arrayAppend<T>(a: [T], b: [T]) : [T]{
        let buffer = Buffer.Buffer<T>(1);
        for (t in a.vals()){
            buffer.add(t);
        };
        for (t in b.vals()){
            buffer.add(t);
        };
        return Buffer.toArray(buffer);
    };
  public func generateTxid(_canister: Principal, _caller: AccountId, _nonce: Nat): Txid{
    let canister: [Nat8] = Blob.toArray(Principal.toBlob(_canister));
    let caller: [Nat8] = Blob.toArray(_caller);
    let nonce32: [Nat8] = Binary.BigEndian.fromNat32(Nat32.fromIntWrap(_nonce));
    let nonce64: [Nat8] = Binary.BigEndian.fromNat64(Nat64.fromIntWrap(_nonce));
    let nat32Max: Nat = 2**32 - 1;
    let txInfo = arrayAppend(arrayAppend(canister, caller), if (_nonce <= nat32Max){ nonce32 }else{ nonce64 });
    let h224: [Nat8] = SHA224.sha224(txInfo);
    return Blob.fromArray(arrayAppend(nonce32, h224));
  };
}
