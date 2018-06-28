pragma solidity ^0.4.18;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./CustomWagers.sol"; 
import "./Wagers.sol";
import "./Rewards.sol";
import "./Mevu.sol";

contract CancelController is Ownable {

    CustomWagers private customWagers;
    Wagers private wagers;
    Rewards private rewards;
    Mevu private mevu;

    modifier onlyBettorCustom (bytes32 wagerId) {
        require (msg.sender == customWagers.getMaker(wagerId) || msg.sender == customWagers.getTaker(wagerId));
        _;
    }

    modifier onlyBettorStandard (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }

    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier notSettledCustom(bytes32 wagerId) {
        require (!customWagers.getSettled(wagerId));
        _;           
    }

    modifier notSettledStandard(bytes32 wagerId) {
        require (!wagers.getSettled(wagerId));
        _;           
    }  

    modifier notTakenCustom (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) == address(0));
        _;
    }

    modifier notTakenStandard (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) == address(0));
        _;
    }

    modifier mustBeTakenCustom (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) != address(0));
        _;
    }

    modifier mustBeTakenStandard (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) != address(0));
        _;
    }

    function setMevuContract (address thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }

    function setCustomWagersContract (address thisAddr) external onlyOwner {
        customWagers = CustomWagers(thisAddr);        
    }

    function setWagersContract (address thisAddr) external onlyOwner {
        wagers = Wagers(thisAddr);        
    }

    function setRewardsContract (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);        
    }

    function cancelWagerStandard (
        bytes32 wagerId,
        bool withdraw      
    ) 
        onlyBettorStandard(wagerId)
        notPaused
        notTakenStandard(wagerId)           
        external 
    {  
        wagers.setSettled(wagerId);                  
        if (withdraw) {
            rewards.subEth(msg.sender, wagers.getOrigValue(wagerId));                
            //msg.sender.transfer (customWagers.getOrigValue(wagerId));
            mevu.transferEth(msg.sender, wagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, wagers.getOrigValue(wagerId));
        }            
    }

     function cancelWagerCustom (
        bytes32 wagerId,
        bool withdraw 
       
    ) 
        onlyBettorCustom(wagerId)
        notPaused      
        notTakenCustom(wagerId)          
        external 
    { 
        customWagers.setSettled(wagerId);                
        if (withdraw) {
            rewards.subEth(msg.sender, customWagers.getOrigValue(wagerId));                
            //msg.sender.transfer (customWagers.getOrigValue(wagerId));
            mevu.transferEth(msg.sender, customWagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, customWagers.getOrigValue(wagerId));
        }            
    }
  
  
    function requestCancelCustom (bytes32 wagerId)
        onlyBettorCustom(wagerId)        
        mustBeTakenCustom(wagerId)
        notSettledCustom(wagerId)
        external
    {
        if (msg.sender == customWagers.getTaker(wagerId)) {            
            customWagers.setTakerCancelRequest(wagerId);
        } else {
            customWagers.setMakerCancelRequest(wagerId);
        }
    }

      
    function requestCancelStandard (bytes32 wagerId)
        onlyBettorStandard(wagerId)
        mustBeTakenStandard(wagerId)       
        notSettledStandard(wagerId)
        external
    {
        if (msg.sender == wagers.getTaker(wagerId)) {            
            wagers.setTakerCancelRequest(wagerId);
        } else {
            wagers.setMakerCancelRequest(wagerId);
        }
    }
  
    function confirmCancelCustom (bytes32 wagerId)
        notSettledCustom(wagerId)
        external 
    {
        if (customWagers.getMakerCancelRequest(wagerId) && customWagers.getTakerCancelRequest(wagerId)) {
           abortWagerCustom(wagerId);
        }
    }

    function confirmCancelStandard (bytes32 wagerId)
        notSettledStandard(wagerId)
        external 
    {
        if (wagers.getMakerCancelRequest(wagerId) && wagers.getTakerCancelRequest(wagerId)) {
           abortWagerStandard(wagerId);
        }
    }

    function abortWagerCustom(bytes32 wagerId) internal {        
        address maker = customWagers.getMaker(wagerId);
        address taker = customWagers.getTaker(wagerId);
        customWagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, customWagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(customWagers.getTaker(wagerId), (customWagers.getWinningValue(wagerId) - customWagers.getOrigValue(wagerId)));
        }             
    }

    function abortWagerStandard(bytes32 wagerId) internal {        
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }             
    }  

    

 

}