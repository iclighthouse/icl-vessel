import Time "mo:base/Time";
import Result "mo:base/Result";
import DRC205 "DRC205";

module {
    public type DexName = Text;
    public type TokenStd = DRC205.TokenStd; 
    public type TokenSymbol = Text;
    public type TokenInfo = (Principal, TokenSymbol, TokenStd);
    //public type Pair = (Principal, Principal);
    public type PairCanister = Principal;
    public type PairRequest = {
        token0: TokenInfo; 
        token1: TokenInfo; 
        dexName: DexName; 
    };
    public type SwapPair = {
        token0: TokenInfo; 
        token1: TokenInfo; 
        dexName: DexName; 
        canisterId: PairCanister;
        feeRate: Float; 
    };
    public type Txid = Blob;
    public type AccountId = Blob;
    public type Nonce = Nat;
    public type Address = Text;
    public type TrieList<K, V> = {data: [(K, V)]; total: Nat; totalPage: Nat; };
    public type NFTUser = {
        #address : Text;
        #principal : Principal;
    };
    public type NFTID = Text;
    public type NFTType = {#NEPTUNE/*0-4*/; #URANUS/*5-14*/; #SATURN/*15-114*/; #JUPITER/*115-314*/; #MARS/*315-614*/; #EARTH/*615-1014*/; #VENUS/*1015-1514*/; #MERCURY/*1515-2021*/; #UNKNOWN};
    public type CollectionId = Principal;
    public type NFT = (NFTUser, NFTID, balance: Nat, NFTType, CollectionId);
    public type Self = actor {
        getTokens : shared query () -> async [TokenInfo];
        getPairs : shared query (_page: ?Nat, _size: ?Nat) -> async TrieList<PairCanister, SwapPair>;
        getPairsByToken : shared query (_token: Principal) -> async [(PairCanister, SwapPair)];
        route : shared query (_token0: Principal, _token1: Principal) -> async [(PairCanister, SwapPair)];
        // NFT
        NFTs : shared query () -> async [(AccountId, [NFT])];
        NFTBalance : shared query (_owner: Address) -> async [NFT];
        NFTBindingMakers : shared query (_nftId: NFTID) -> async [(pair: Principal, account: AccountId)];
        NFTDeposit : shared (_collectionId: CollectionId, _nftId: NFTID, _sa: ?[Nat8]) -> async ();
        NFTBindMaker : shared (_nftId: NFTID, _pair: Principal, _maker: AccountId, _sa: ?[Nat8]) -> async ();
        NFTUnbindMaker : shared (_nftId: NFTID, _pair: Principal, _maker: AccountId, _sa: ?[Nat8]) -> async ();
        NFTWithdraw : shared (_nftId: ?NFTID, _sa: ?[Nat8]) -> async ();
        // Maker
        maker_getPublicMakers : shared query (_pair: ?Principal, _page: ?Nat, _size: ?Nat) -> async TrieList<PairCanister, [(Principal, AccountId)]>;
        maker_getPrivateMakers : shared query (_account: AccountId, _page: ?Nat, _size: ?Nat) -> async TrieList<PairCanister, [(Principal, AccountId)]>;
        maker_create : shared (_arg: {
            pair: Principal;
            allow: {#Public; #Private};
            name: Text; // "AAA_BBB DeMM-1"
            lowerLimit: Nat; //Price
            upperLimit: Nat; //Price
            spreadRate: Nat; // e.g. 10000, ppm  x/1000000
            threshold: Nat; // e.g. 1000000000000 token1, After the total liquidity exceeds this threshold, the LP adds liquidity up to a limit of volFactor times his trading volume.
            volFactor: Nat; // e.g. 2
            creator: ?AccountId;
        }) -> async (canister: Principal);
        maker_update : shared (_pair: Principal, _maker: Principal, _name:?Text, _version: Text) -> async (canister: ?Principal);
        maker_rollback : shared (_pair: Principal, _maker: Principal) -> async (canister: ?Principal);
        maker_remove : shared (_pair: Principal, _maker: Principal) -> async ();
    };
};