pragma solidity ^0.4.18; 
import "./Rewards.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Mevu.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Wagers is Ownable {

    Events events;
    Admin admin;    
    Rewards rewards;
    Mevu mevu;

    struct Wager {
        bytes32 eventId;        
        uint origValue;
        uint winningValue;        
        uint makerChoice;
        uint takerChoice;
        uint odds;
        uint makerWinnerVote;
        uint takerWinnerVote;
        address maker;
        address taker;        
        address winner;
        address loser;
        bool makerCancelRequest;
        bool takerCancelRequest;
        bool locked;
        bool settled;        
    }

    mapping (bytes32 => Wager) wagersMap;
    mapping (address => mapping (bytes32 => bool)) recdRefund;

     modifier onlyAuth () {
        require(msg.sender == address(admin) ||
                msg.sender == address(this.owner));
                _;
    }

        
    modifier eventUnlocked(bytes32 eventId){
        require (!events.getLocked(eventId));
        _;
    }

    modifier wagerUnlocked (bytes32 wagerId) {
        require (!getLocked(wagerId));
        _;
    }    

    modifier mustBeTaken (bytes32 wagerId) {
        require (getTaker(wagerId) != address(0));
        _;
    }

    modifier notSettled(bytes32 wagerId) {
        require (!getSettled(wagerId));
        _;           
    }

    modifier requireMinWager() {
        require (msg.value >= admin.getMinWagerAmount());
        _;
    }

    modifier checkBalance (uint wagerValue) {
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= wagerValue);
        _;
    }      
    
    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == getMaker(wagerId) || msg.sender == getTaker(wagerId));
        _;
    }

    modifier notTaken (bytes32 wagerId) {
        require (getTaker(wagerId) == address(0));
        _;
    }     

    function setRewardsContract   (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    
    function setEventsContract (address thisAddr) external onlyOwner {
        events = Events(thisAddr);        
    }

    function setMevuContract (address thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }


    





     /** @dev Creates a new Standard wager for a user to take and adds it to the standardWagers mapping.
      * @param wagerId sha3 hash of the msg.sender concat timestamp.
      * @param eventId int id for the standard event the wager is based on.
      * @param odds decimal of maker chosen odds * 100.         
      */
    function makeWager(
        bytes32 wagerId,
        uint value,       
        bytes32 eventId,
        uint odds,
        uint makerChoice
    )
        eventUnlocked(eventId)
        requireMinWager
        checkBalance(value)
        notPaused
        payable 
    {        
        address maker = msg.sender;
        uint takerChoice;
        if (makerChoice == 1) {
          takerChoice = 2;
        } else {
           takerChoice = 1;
        }
        uint winningValue = value + (value / (odds/100));  
        Wager memory thisWager;                
        thisWager = Wager ( eventId,
                            value,
                            winningValue,                            
                            makerChoice,
                            takerChoice,
                            odds,
                            0,
                            0,
                            maker,
                            address(0),                          
                            address(0),
                            address(0),
                            false,
                            false,
                            false,
                            false);
        transferEthToMevu(msg.value);
        wagersMap[wagerId] = thisWager;     
        events.addWager(eventId, wagerId);
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));     
    }

         /** @dev Takes a listed wager for a user -- adds address to StandardWager struct.
      * @param id sha3 hash of the msg.sender concat timestamp.         
      */
    function takeWager (
        bytes32 id      
    )   
        eventUnlocked(getEventId(id))
        wagerUnlocked(id)       
        notPaused
        payable 
    {
        uint expectedValue = getOrigValue(id) / (getOdds(id) / 100);        
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= expectedValue);
        address taker = msg.sender;
        transferEthToMevu(msg.value);
        rewards.subUnlockedEth(msg.sender, (expectedValue - msg.value));        
        rewards.addEth(msg.sender, msg.value);
        
        wagersMap[id].taker = taker;
        wagersMap[id].locked = true; 
        wagersMap[id].winningValue = wagersMap[id].origValue + expectedValue;
        
      
                      
    }    

    function cancelWager (
        bytes32 wagerId, 
        bool withdraw
    ) 
        onlyBettor(wagerId)
        notPaused
        notTaken(wagerId)
        wagerUnlocked(wagerId) 
    {          
        setLocked(wagerId);
        setSettled(wagerId);                   
        if (withdraw) {
            rewards.subEth(msg.sender, getOrigValue(wagerId));                
            msg.sender.transfer (getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, getOrigValue(wagerId));
        }            
    }

    function requestWagerCancel(bytes32 wagerId) 
        mustBeTaken(wagerId) 
        notSettled(wagerId) 
    {       
        if (msg.sender == getTaker(wagerId)) {
            if (getMakerCancelRequest(wagerId)) {            
                setSettled(wagerId);                
                rewards.addUnlockedEth(getMaker(wagerId), getOrigValue(wagerId)); 
                rewards.addUnlockedEth(getTaker(wagerId),  (getWinningValue(wagerId) - getOrigValue(wagerId)));
            } else {
                setTakerCancelRequest(wagerId);
            }
        }
        if (msg.sender ==  getMaker(wagerId)) {
            if (getTakerCancelRequest(wagerId)) {            
                setSettled(wagerId);              
                rewards.addUnlockedEth(getMaker(wagerId), getOrigValue(wagerId));
                rewards.addUnlockedEth(getTaker(wagerId),  (getWinningValue(wagerId) - getOrigValue(wagerId)));
            } else {
                setMakerCancelRequest(wagerId);
            }
        }        
    }

    function transferEthToMevu (uint amount) internal {
        mevu.transfer(amount);
    }   
  
    


   
    function setLocked (bytes32 wagerId) onlyAuth {
        wagersMap[wagerId].locked = true;
    }

    function setSettled (bytes32 wagerId) onlyAuth  {
        wagersMap[wagerId].settled = true;
    }

    function setMakerWinVote (bytes32 id, uint winnerVote) external onlyAuth {
        wagersMap[id].makerWinnerVote = winnerVote;
    }

    function setTakerWinVote (bytes32 id, uint winnerVote) external onlyAuth {
        wagersMap[id].takerWinnerVote = winnerVote;
    }

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth {
        recdRefund[bettor][wagerId] = true;
    }

    function setMakerCancelRequest (bytes32 id)  internal {
        wagersMap[id].makerCancelRequest = true;
    }

    function setTakerCancelRequest (bytes32 id)  internal {
        wagersMap[id].takerCancelRequest = true;
    }

    function setWinner (bytes32 id, address winner) external onlyOwner {
        wagersMap[id].winner = winner;        
    }

    function setLoser (bytes32 id, address loser) external onlyOwner {
        wagersMap[id].loser = loser;
    }

    function getEventId(bytes32 wagerId) view returns (bytes32) {
        return wagersMap[wagerId].eventId;
    }

    function getLocked (bytes32 id) view returns (bool) {
        return wagersMap[id].locked;
    }

    function getSettled (bytes32 id) view returns (bool) {
        return wagersMap[id].settled;
    }

    function getMaker(bytes32 id) view returns (address) {
        return wagersMap[id].maker;
    }

    function getTaker(bytes32 id) view returns (address) {
        return wagersMap[id].taker;
    }

    function getMakerChoice (bytes32 id) view returns (uint) {
        return wagersMap[id].makerChoice;
    }

    function getTakerChoice (bytes32 id) view returns (uint) {
        return wagersMap[id].takerChoice;
    }

    function getMakerCancelRequest (bytes32 id) view returns (bool) {
        return wagersMap[id].makerCancelRequest;
    }

    function getTakerCancelRequest (bytes32 id) view returns (bool) {
        return wagersMap[id].takerCancelRequest;
    }

    function getMakerWinVote (bytes32 id) view returns (uint) {
        return wagersMap[id].makerWinnerVote;
    }

    function getRefund (address bettor, bytes32 wagerId) view returns (bool) {
        return recdRefund[bettor][wagerId];
    }

    function getTakerWinVote (bytes32 id) view returns (uint) {
        return wagersMap[id].takerWinnerVote;
    }

    function getOdds (bytes32 id) view returns (uint) {
        return wagersMap[id].odds;
    }

    function getOrigValue (bytes32 id) view returns (uint) {
        return wagersMap[id].origValue;
    }

    function getWinningValue (bytes32 id) view returns (uint) {
        return wagersMap[id].winningValue;

    }

    function getWinner (bytes32 id) view returns (address) {
        return wagersMap[id].winner;
    }

    function getLoser (bytes32 id) view returns (address) {
        return wagersMap[id].loser;
    }

}