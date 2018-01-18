pragma solidity ^0.4.18; 
import "./Rewards.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Wagers.sol";
import "./Mevu.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract WagersController is Ownable {
    mapping (address => bool) private isAuthorized; 
    Mevu mevu;   
    Wagers wagers;
    Events events;
    Admin admin;    
    Rewards rewards;  
    
    modifier onlyAuth () {
        require(isAuthorized[msg.sender]);               
        _;
    }

    modifier requireMinWager() {
        require (msg.value >= admin.getMinWagerAmount());
        _;
    }

 modifier eventUnlocked(bytes32 eventId){
        require (!events.getLocked(eventId));
        _;
    }

    modifier wagerUnlocked (bytes32 wagerId) {
        require (!wagers.getLocked(wagerId));
        _;
    }    

    modifier mustBeTaken (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) != address(0));
        _;
    }

    modifier notSettled(bytes32 wagerId) {
        require (!wagers.getSettled(wagerId));
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
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }

    modifier notTaken (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) == address(0));
        _;
    } 

    modifier notMade (bytes32 wagerId) {        
        require (wagers.getMaker(wagerId) != address(0));
        _;
    }    

    function grantAuthority (address nowAuthorized) onlyOwner {
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) onlyOwner {
        isAuthorized[unauthorized] = false;
    }

    function setMevuContract (address thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }

    function setWagersContract (address thisAddr) external onlyOwner {
        wagers = Wagers(thisAddr);        
    }

    function setRewardsContract (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }
    
    function setEventsContract (address thisAddr) external onlyOwner {
        events = Events(thisAddr);        
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
        notMade(wagerId)
        eventUnlocked(eventId)
        requireMinWager
        checkBalance(value)
        notPaused
        payable 
    {        
       
        uint takerChoice;
        if (makerChoice == 1) {
          takerChoice = 2;
        } else {
           takerChoice = 1;
        }
        uint winningValue = value + (value / (odds/100));                     
        wagers.makeWager  ( wagerId,
                            eventId,
                            value,
                            winningValue,                            
                            makerChoice,
                            takerChoice,
                            odds,
                            0,
                            0,
                            msg.sender);
        transferEthToMevu(msg.value);
        mevu.addToPlayerFunds(msg.value);      
        //events.addWager(eventId, wagerId);
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));     
    }

     /** @dev Takes a listed wager for a user -- adds address to StandardWager struct.
      * @param id sha3 hash of the msg.sender concat timestamp.         
      */
    function takeWager (
        bytes32 id      
    )   
        eventUnlocked(wagers.getEventId(id))
        wagerUnlocked(id)       
        notPaused
        payable 
    {
        uint expectedValue = wagers.getOrigValue(id) / (wagers.getOdds(id) / 100);        
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= expectedValue);
        address taker = msg.sender;
        transferEthToMevu(msg.value);
        mevu.addToPlayerFunds(msg.value);
        rewards.subUnlockedEth(msg.sender, (expectedValue - msg.value));        
        rewards.addEth(msg.sender, msg.value);
        uint winningValue = wagers.getOrigValue(id) + expectedValue;
        wagers.setTaker(id, taker);
        wagers.setLocked(id);
        wagers.setWinningValue(id, winningValue);        
        events.addWager(wagers.getEventId(id), winningValue);    
                      
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
        wagers.setLocked(wagerId);
        wagers.setSettled(wagerId);                   
        if (withdraw) {
            rewards.subEth(msg.sender, wagers.getOrigValue(wagerId));                
            msg.sender.transfer (wagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, wagers.getOrigValue(wagerId));
        }            
    }

    function requestWagerCancel(bytes32 wagerId) 
        mustBeTaken(wagerId) 
        notSettled(wagerId) 
    {       
        if (msg.sender == wagers.getTaker(wagerId)) {
            if (wagers.getMakerCancelRequest(wagerId)) {            
                wagers.setSettled(wagerId);
                events.removeWager(wagers.getEventId(wagerId), wagers.getWinningValue(wagerId));                
                rewards.addUnlockedEth(wagers.getMaker(wagerId), wagers.getOrigValue(wagerId)); 
                rewards.addUnlockedEth(wagers.getTaker(wagerId),  (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
            } else {
                wagers.setTakerCancelRequest(wagerId);
            }
        }
        if (msg.sender ==  wagers.getMaker(wagerId)) {
            if (wagers.getTakerCancelRequest(wagerId)) {            
                wagers.setSettled(wagerId);
                events.removeWager(wagers.getEventId(wagerId), wagers.getWinningValue(wagerId));              
                rewards.addUnlockedEth(wagers.getMaker(wagerId), wagers.getOrigValue(wagerId));
                rewards.addUnlockedEth(wagers.getTaker(wagerId),  (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
            } else {
                wagers.setMakerCancelRequest(wagerId);
            }
        }        
    }

    function transferEthToMevu (uint amount) internal {
        mevu.transfer(amount);
    } 

}