pragma solidity 0.4.18;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Admin.sol"; 
import "./CustomWagers.sol"; 
import "./Events.sol";
import "./Rewards.sol";
import "./Mevu.sol";

contract CustomWagersController is Ownable {
    Admin private admin;
    Events private events;
    Rewards private rewards;
    CustomWagers private customWagers;
    Mevu private mevu; 
   
    modifier mustBeTaken (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) != address(0));
        _;
    }
 
    modifier mustBeEnded (bytes32 wagerId) {
        require (customWagers.getEndTime(wagerId) > block.timestamp);
        _;
    }

    modifier notSettled(bytes32 wagerId) {
        require (!customWagers.getSettled(wagerId));
        _;           
    }  

    modifier checkBalance (uint wagerValue) {
        require (wagerValue >= admin.getMinWagerAmount());
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= wagerValue);
        _;
    }      
    
    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == customWagers.getMaker(wagerId) || msg.sender == customWagers.getTaker(wagerId));
        _;
    }

    modifier notTaken (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) == address(0));
        _;
    } 

    modifier notMade (bytes32 wagerId) {        
        require (customWagers.getMaker(wagerId) == address(0));
        _;
    }

    modifier notOver (bytes32 wagerId) {
        require (block.timestamp < customWagers.getEndTime(wagerId));
        _;
    }     

    function setCustomWagersContract (address thisAddr) external onlyOwner {
        customWagers = CustomWagers(thisAddr);        
    }

    function setRewardsContract (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);        
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setMevuContract (address thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }

    function makeWager (
        bytes32 id,
        uint endTime,
        uint makerChoice,
        uint value,
        uint odds,
        address judge
        )
        notMade(id)    
        checkBalance(value)
        notPaused
        external
        payable
    {
        uint takerChoice;
        if (makerChoice == 1) {
          takerChoice = 2;
        } else {
           takerChoice = 1;
        }
             
        customWagers.makeWager  ( id,
                            endTime,                            
                            value,
                            value + (value / (odds/100)),                            
                            makerChoice,
                            takerChoice,
                            odds,
                            0,
                            0,
                            msg.sender,
                            judge);
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));
        address(mevu).transfer(msg.value);
    }


    function takeWager (
        bytes32 id,
        address judge      
    )
        notTaken(id)
        notOver(id)
        payable
    {
        require (judge == customWagers.getJudge(id));
        uint expectedValue = customWagers.getOrigValue(id) / (customWagers.getOdds(id) / 100);
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= expectedValue);         
        rewards.subUnlockedEth(msg.sender, (expectedValue - msg.value));        
        rewards.addEth(msg.sender, msg.value);
        customWagers.setTaker(id, msg.sender);      
        address(mevu).transfer(msg.value);
    }


    function submitVote (      
        bytes32 wagerId,
        uint winnerVote
    ) 
        onlyBettor(wagerId) 
        mustBeEnded(wagerId)
           notSettled(wagerId)
        notPaused 
    {       
        if (msg.sender == customWagers.getMaker(wagerId)){        
            customWagers.setMakerWinVote (wagerId, winnerVote);
        } else {
            customWagers.setTakerWinVote (wagerId, winnerVote);
        }
        
        if (customWagers.getTakerWinVote(wagerId) != 0 && customWagers.getMakerWinVote(wagerId) != 0) {
            settle(wagerId);            
        }  
    }

    function submitJudgeVote (bytes32 wagerId, uint vote)
        mustBeEnded(wagerId)                       
    {
        require(customWagers.getJudgesVote(wagerId) == 0);
        require(customWagers.getJudge(wagerId) == msg.sender);
        customWagers.setJudgesVote(wagerId, vote);
    } 

   
    function settle(bytes32 wagerId) internal {
        address maker = customWagers.getMaker(wagerId);
        address taker = customWagers.getMaker(wagerId);
        uint origValue = customWagers.getOrigValue(wagerId);
        uint payoutValue = customWagers.getWinningValue(wagerId); 
        uint fee = (payoutValue/100) * 2; // Sevice fee is 2 percent
        uint makerWinVote = customWagers.getMakerWinVote(wagerId);
        payoutValue -= fee; 
         mevu.addMevuBalance(3*(fee/4)); 
         mevu.addLotteryBalance(fee/8);
        if (makerWinVote == customWagers.getTakerWinVote(wagerId)) {
            if (makerWinVote == customWagers.getMakerChoice(wagerId)) {
                customWagers.setWinner(wagerId, maker);
                rewards.subEth(maker, origValue);                
                rewards.subEth(taker, customWagers.getWinningValue(wagerId) - origValue);
            } else {
                if (makerWinVote == 3) {
                    customWagers.setWinner(wagerId, address(0));                    
                } else {
                    rewards.subEth(taker, customWagers.getWinningValue(wagerId) - origValue);
                    customWagers.setWinner(wagerId, taker);                   
                    rewards.subEth(maker, origValue);
                }
            }
            payout(wagerId, maker, taker, payoutValue);
        } else {
            checkJudge(wagerId, maker, taker, makerWinVote, customWagers.getTakerWinVote(wagerId), origValue, payoutValue);
        }     
    }


    // Checks to see if there has been a judge appointed, if so, checks to see if they've voted yet
    function checkJudge (bytes32 wagerId, address maker, address taker, uint makerWinVote, uint takerWinVote, uint origValue, uint payoutValue) internal {
       
        if (customWagers.getJudge(wagerId) != address (0)) {
             uint judgesVote = customWagers.getJudgesVote(wagerId);
            // check judgesVote[wagerId]            
            if (judgesVote == makerWinVote) {
                customWagers.setWinner(wagerId, maker);
                rewards.subEth(maker, origValue);                
                rewards.subEth(taker, customWagers.getWinningValue(wagerId) - origValue);
                payout(wagerId, maker, taker, payoutValue);
            }
            if (judgesVote == takerWinVote) {
                rewards.subEth(taker, customWagers.getWinningValue(wagerId) - origValue);
                customWagers.setWinner(wagerId, taker);                   
                rewards.subEth(maker, origValue);
            }
            if (judgesVote == 3) {
                abortWager(wagerId);
            }
        } else {
            abortWager(wagerId);
        }        
    }  

   
    function payout(bytes32 wagerId, address maker, address taker, uint payoutValue) internal {  
            require(!customWagers.getSettled(wagerId));
            customWagers.setSettled(wagerId);           
            uint origVal =  customWagers.getOrigValue(wagerId);
            uint winVal = customWagers.getWinningValue(wagerId);
            address winner = customWagers.getWinner(wagerId);
             if (winner == address(0)) { //Tie
                mevu.transferEth(maker, origVal);
                mevu.transferEth(taker, winVal-origVal);                 
             } else {            
                      
                mevu.transferEth(winner, payoutValue);                          
            }                             
            rewards.addPlayerRep(maker, admin.getPlayerAgreeRepReward());
            rewards.addPlayerRep(taker, admin.getPlayerAgreeRepReward());             
    }


    function cancelWager (
        bytes32 wagerId, 
        bool withdraw
    ) 
        onlyBettor(wagerId)
        notPaused
        notTaken(wagerId)        
        external 
    {           
        customWagers.setSettled(wagerId);                   
        if (withdraw) {
            rewards.subEth(msg.sender, customWagers.getOrigValue(wagerId));                
            msg.sender.transfer (customWagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, customWagers.getOrigValue(wagerId));
        }            
    }
  
    function requestCancel (bytes32 wagerId)
        onlyBettor(wagerId)
        mustBeTaken(wagerId)
        notSettled(wagerId)
        external
    {
        if (msg.sender == customWagers.getTaker(wagerId)) {            
            customWagers.setTakerCancelRequest(wagerId);
        } else {
            customWagers.setMakerCancelRequest(wagerId);
        }
    }
  
    function confirmCancel (bytes32 wagerId)
        notSettled(wagerId)
        external 
    {
        if (customWagers.getMakerCancelRequest(wagerId) && customWagers.getTakerCancelRequest(wagerId)) {
           abortWager(wagerId);
        }
    }

    function withdraw(
        uint eth    
    )
        notPaused   
        external         
    { 
        require (rewards.getUnlockedEthBalance(msg.sender) >= eth);
        rewards.subUnlockedEth(msg.sender, eth);
        rewards.subEth(msg.sender, eth);
        //playerFunds -= eth;
        mevu.transferEth(msg.sender, eth);         
    }        

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
     *  been cancelled, refunds all eth.               
     *  @param wagerId bytes32 wagerId of the wager to abort.  
     */ 
    function abortWager(bytes32 wagerId) internal {        
        address maker = customWagers.getMaker(wagerId);
        address taker = customWagers.getTaker(wagerId);
        customWagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, customWagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(customWagers.getTaker(wagerId), (customWagers.getWinningValue(wagerId) - customWagers.getOrigValue(wagerId)));
        }             
    }   
}