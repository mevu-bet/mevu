pragma solidity ^0.5.0;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Admin.sol"; 
import "./PoolWagers.sol"; 
import "./Events.sol";
import "./Rewards.sol";
import "./Mevu.sol";


contract PoolWagersController is Ownable {
    Admin admin;
    Events events;
    Rewards rewards;
    PoolWagers poolWagers;
    Mevu mevu;

    event Aborted(bytes32 wagerId);
    event WagerMade(bytes32 id); 
    event WagerTaken(bytes32 id);    
    event VoteSubmit (bytes32 wagerId);
    event Winner (address winner);  

    modifier eventNotOver(bytes32 eventId){
        require (!events.getVoteReady(eventId));
        _;
    }

    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier notClaimed(bytes32 wagerId) {
        require (!poolWagers.getSettled(wagerId));
        _;
    }
    
    modifier checkBalance (uint wagerValue) {
        require (wagerValue >= admin.getMinWagerAmount());
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= wagerValue);
        _;
    }   
    
    modifier notMade (bytes32 wagerId) {        
        require (poolWagers.getMaker(wagerId) == address(0));
        _;
    }

    modifier isWinner (bytes32 wagerId) {
        require (poolWagers.getMakerChoice(wagerId) == events.getWinner(poolWagers.getEventId(wagerId)));
        _;
    }    

    function setPoolWagersContract (address thisAddr) external onlyOwner { poolWagers = PoolWagers(thisAddr); }

    function setEventsContract (address thisAddr) external onlyOwner { events = Events(thisAddr); }

    function setRewardsContract (address thisAddr) external onlyOwner { rewards = Rewards(thisAddr); }

    function setAdminContract (address thisAddr) external onlyOwner { admin = Admin(thisAddr); }

    function setMevuContract (address payable thisAddr) external onlyOwner { mevu = Mevu(thisAddr); }

    function makeWager(
        bytes32 wagerId,            
        bytes32 eventId,
        uint value,     
        uint makerChoice
    )    
    notMade(wagerId)
    eventNotOver(eventId)   
    checkBalance(value)
    notPaused
    external
    payable
    {
        require(makerChoice <= events.getNumOutcomes(eventId));      
   
        poolWagers.makeWager( 
            wagerId,
            eventId,
            value,                                      
            makerChoice,          
            msg.sender);        
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));
        address(mevu).transfer(msg.value);
        events.addWagerForTeam(eventId, value, makerChoice);    
        emit WagerMade(wagerId);
    }

    function claimWin (bytes32 wagerId)
        isWinner(wagerId)
        notClaimed(wagerId)
        notPaused
        external        
    {
        bytes32 eventId = poolWagers.getEventId(wagerId);
        uint makerChoice = poolWagers.getMakerChoice(wagerId);
        uint totalBetForMakerChoice = events.getTotalAmountBetForTeam(eventId, makerChoice);
        uint totalBetOnEvent = events.getTotalAmountBet(eventId);
        uint origBet = poolWagers.getOrigValue(wagerId);
       
        // Ensure claim is valid       
        require (totalBetOnEvent > totalBetForMakerChoice);
        
        // Set as settled to protect against re-entrance
        poolWagers.setSettled(wagerId);
        
        //calculate winnings
        uint winningsPool = totalBetOnEvent - totalBetForMakerChoice;
        uint reward = determineReward(totalBetForMakerChoice, origBet, winningsPool);
        
        // Disperse Winnings
        rewards.subEth(msg.sender, origBet);
        mevu.transferEth(msg.sender, reward);
    }

    function determineReward(uint256 subtotal, uint256 yourStake, uint256 betForOpponent) internal view returns (uint256){
        uint256 fraction = subtotal/100000000;
        uint256 yourPercentage = yourStake/fraction;
        uint256 yourReward = ((((betForOpponent/100000000) * yourPercentage) + yourStake)/100) * 97;
        return yourReward;   
    }

    function claimRefund (bytes32 wagerId) notPaused external {
        bytes32 eventId = poolWagers.getEventId(wagerId);
        uint value = poolWagers.getOrigValue(wagerId);
        require (events.getLocked(eventId));
        require (events.getTotalAmountBet(eventId) == events.getTotalAmountBetForTeam(eventId, poolWagers.getMakerChoice(wagerId)));
        require(!poolWagers.getSettled(wagerId));
        poolWagers.setSettled(wagerId);
        rewards.subEth(msg.sender, value);
        mevu.transferEth(msg.sender, value);     
    }
}