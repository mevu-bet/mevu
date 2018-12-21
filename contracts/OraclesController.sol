pragma solidity ^0.4.18;
import "./Events.sol";
import "./Oracles.sol";
import "./OracleVerifier.sol";
import "./Rewards.sol";
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./MvuToken.sol";
import "./Admin.sol";
import "./Mevu.sol";

contract OraclesController is Ownable {
    Events events;
    OracleVerifier oracleVerif;
    Rewards rewards;
    Admin admin;
    MvuToken mvuToken;
    Mevu mevu;
    Oracles oracles;

    event OracleRegistered(address oracle, bytes32 eventId);
    event WithConsensus (address oracle);
    event AgainstConsensus (address oracle);


    modifier eventUnlocked(bytes32 eventId){
        require (!events.getLocked(eventId));
        _;
    }

    modifier eventLocked (bytes32 eventId){
        require (events.getLocked(eventId));
        _;
    }

    modifier onlyOracle (bytes32 eventId) {
        require (oracles.checkOracleStatus(msg.sender, eventId));
        _;
    }

    modifier onlyVerified() {
        require (oracleVerif.checkVerification(msg.sender));
        _;
    }


    modifier mustBeVoteReady(bytes32 eventId) {
        require (events.getVoteReady(eventId));
        _;
    }

    modifier notClaimed (bytes32 eventId) {
        require (!oracles.getPaid(eventId, msg.sender));
        _;
    }

    modifier noWinner (bytes32 eventId) {
        require (events.getWinner(eventId) == events.getNumOutcomes(eventId));
        _;
    }

    modifier refundNotClaimed (bytes32 eventId) {
        require (!oracles.getRefunded(eventId, msg.sender));
        _;
    }

    modifier thresholdReached (bytes32 eventId) {
        require (oracles.getThreshold(eventId));
        _;
    }

    function setOracleVerifContract (address thisAddr) external onlyOwner { oracleVerif  = OracleVerifier(thisAddr); }

    function setRewardsContract (address thisAddr) external onlyOwner { rewards = Rewards(thisAddr); }

    function setEventsContract (address thisAddr) external onlyOwner { events = Events(thisAddr); }

    function setAdminContract (address thisAddr) external onlyOwner { admin = Admin(thisAddr); }

    function setOraclesContract (address thisAddr) external onlyOwner { oracles = Oracles(thisAddr); }

    function setMevuContract (address thisAddr) external onlyOwner { mevu = Mevu(thisAddr); }

    function setMvuTokenContract (address thisAddr) external onlyOwner { mvuToken = MvuToken(thisAddr); }

    // function setMevuContract (address thisAddr) external onlyOwner {
    //     mevu = Mevu(thisAddr);
    // }

    /** @dev Registers a user as an Oracle for the chosen event. Before being able to register the user must
      * allow the contract to move their MVU through the Token contract.
      * @param eventId int id for the standard event the oracle is registered for.
      * @param mvuStake Amount of mvu (in lowest base unit) staked.
      * @param winnerVote uint of who they voted as winning
    */
    function registerOracle (
    bytes32 eventId,
    uint mvuStake,
    uint winnerVote
    )
        eventUnlocked(eventId)
        onlyVerified
        mustBeVoteReady(eventId)
        external
    {
        //require (keccak256(strConcat(addrToString(msg.sender),  bytes32ToString(eventId))) == oracleId);
        require (!oracles.getRegistered(msg.sender, eventId));
        require(mvuStake >= admin.getMinOracleStake());
        //require(winnerVote == 1 || winnerVote == 2 || winnerVote == 3);
        oracles.setRegistered(msg.sender, eventId);
        bytes32 empty;
        if (oracles.getLastEventOraclized(msg.sender) == empty) {
            oracles.addToOracleList(msg.sender);
        }
        oracles.setLastEventOraclized(msg.sender, eventId) ;
        //transferTokensToMevu(msg.sender, mvuStake);
        mvuToken.transferFrom(msg.sender, address(this), mvuStake);
        oracles.addOracle (msg.sender, eventId, mvuStake, winnerVote, admin.getMinOracleNum(eventId));
        rewards.addMvu(msg.sender, mvuStake);
        emit OracleRegistered(msg.sender, eventId);

    }

    // Called by oracle to get paid after event voting closes
    function claimReward (bytes32 eventId)
        onlyOracle(eventId)
        notClaimed(eventId)
        eventLocked(eventId)
        thresholdReached(eventId)
    {
        oracles.setPaid(msg.sender, eventId);
        uint ethReward;
        uint mvuReward;
        uint mvuRewardPool;

        // if (events.getWinner(eventId) == 1) {
        //     mvuRewardPool = oracles.getTotalOracleStake(eventId) - oracles.getStakeForOne(eventId);
        // }
        // if (events.getWinner(eventId) == 2) {
        //     mvuRewardPool = oracles.getTotalOracleStake(eventId) - oracles.getStakeForTwo(eventId);
        // }
        // if (events.getWinner(eventId) == 3) {
        //     mvuRewardPool = oracles.getTotalOracleStake(eventId) - oracles.getStakeForThree(eventId);
        // }
        uint winner = events.getWinner(eventId);

        mvuRewardPool = oracles.getTotalOracleStake(eventId) - oracles.getStakeForOutcome(eventId, winner);

        uint twoPercentRewardPool = 2 * events.getTotalAmountResolvedWithoutOracles(eventId);
        twoPercentRewardPool /= 100;
        uint threePercentRewardPool = 3 * (events.getTotalAmountBet(eventId) - events.getTotalAmountResolvedWithoutOracles(eventId));
        threePercentRewardPool /= 100;
        uint totalRewardPool = (threePercentRewardPool/12) + (threePercentRewardPool/3) + (twoPercentRewardPool/8);
        uint stakePercentage = 100000 * oracles.getMvuStake(eventId, msg.sender);
        stakePercentage /= (oracles.getTotalOracleStake(eventId) - mvuRewardPool);
        mvuRewardPool /= 2;


        if (oracles.getWinnerVote(eventId, msg.sender) == events.getCurrentWinner(eventId)) {
            ethReward = (totalRewardPool/100000) * stakePercentage;
            rewards.addUnlockedEth(msg.sender, ethReward);
            rewards.addEth(msg.sender, ethReward);
            mvuReward = (mvuRewardPool/100000) * stakePercentage;
            rewards.addMvu(msg.sender, mvuReward);
            mvuReward += oracles.getMvuStake(eventId, msg.sender);
            rewards.addUnlockedMvu(msg.sender, mvuReward);
            rewards.addOracleRep(msg.sender, admin.getOracleRepReward());
            emit WithConsensus(msg.sender);
        } else {
            mvuReward = oracles.getMvuStake(eventId, msg.sender)/2;
            rewards.subMvu(msg.sender, mvuReward);
            rewards.addUnlockedMvu(msg.sender, mvuReward);
            rewards.subOracleRep(msg.sender, admin.getOracleRepPenalty());
            emit AgainstConsensus(msg.sender);
        }
    }

    // called by oracle to get refund if not enough oracles register and oracle settlement is cancelled
    function claimRefund (bytes32 eventId)
        refundNotClaimed(eventId)
        onlyOracle(eventId)
        eventLocked(eventId)
        noWinner(eventId)
    {
        oracles.setRefunded(msg.sender, eventId);
        uint amount;
        amount = oracles.getMvuStake(eventId, msg.sender);
        //assert(rewards.getMvuBalance(msg.sender) >= amount);
        rewards.addUnlockedMvu(msg.sender, amount);
       // rewards.subMvu(msg.sender, amount);
       // mevu.transferTokensFromMevu(msg.sender, amount);
    }

    function transferTokensToMevu (address oracle, uint mvuStake) internal {
        mvuToken.transferFrom(oracle, mevu, mvuStake);
    }

    function withdraw (uint mvu) external {
        require (rewards.getUnlockedMvuBalance(msg.sender) >= mvu);
        rewards.subUnlockedMvu(msg.sender, mvu);
        rewards.subMvu(msg.sender, mvu);
        mvuToken.transfer(msg.sender, mvu);
        //mevu.transferTokensFromMevu (msg.sender, mvu);
    }




}