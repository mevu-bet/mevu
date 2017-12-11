pragma solidity 0.4.18;

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";



contract Rewards is Ownable {
    
    
    
   
   

    mapping(address => uint) public playerRep;
    mapping (address => uint) public oracleRep;    

    mapping (address => uint) public ethBalance;
    mapping (address => uint) public mvuBalance;

    mapping(address => uint) public unlockedEthBalance;
    mapping (address => uint) public unlockedMvuBalance;   
    

    
       

    function oracleRewards(uint eventId) private {
        // if winner = 0 it means oracleRefund(thisEvent)
        // if winner = 3 it means tie
        // reward oracles with eth and mvu proprotionate to their stake as well as adjust reps accourdingly
        // oracle struct.paid = true
        //pay and reward right oracles the higher fee and rep and mvu from wrong oracles
        //punish wrong oracles and those who didn't vote with reputation loss and by losing mvu stake

        uint stakeForfeit = 0;
        address[] correctOracles;
        bytes32[] correctStructs;
        uint totalCorrectStake = 0;

        if (mevu.getWinner(eventId) == 0) {
            oracleRefund(eventId);
        } else {
            // find disagreement or non voters 
            for (uint i = 0; i < mevu.getStandardEventOraclesLength(eventId); i++) {
                
                address thisOracle = mevu.getStandardEventOracleAt(eventId, i);
            
                bytes32 thisStruct;
                for (uint x = 0; x < mevu.getOracleLength(thisOracle); x++){
                    if (mevu.getEventId(mevu.getOracleAt(thisOracle, x)) == eventId) {
                        thisStruct = mevu.getOracleAt(thisOracle, x);
                    }
                }
                mevu.setOraclePaid(thisStruct);
                
                if (mevu.getWinnerVote(thisStruct) != 0){
                    if (mevu.getWinnerVote(thisStruct) == mevu.getWinner(eventId)) {
                        // hooray, was right, reward
                        addOracleRep(thisOracle, mevu.getMvuStake(thisStruct));
                        correctOracles.push(thisOracle);
                        correctStructs.push(thisStruct); 
                        totalCorrectStake += mevu.getMvuStake(thisStruct);
                                                                    
                    } else {
                        // boo, was wrong or lying, punish
                        subOracleRep(thisOracle, mevu.getMvuStake(thisStruct));
                        mvuBalance[thisOracle] -= mevu.getMvuStake(thisStruct);
                        stakeForfeit += mevu.getMvuStake(thisStruct);                        
                    }                
                } else {
                    //nonVoter, punish
                    subOracleRep(thisOracle, mevu.getMvuStake(thisStruct));
                    mvuBalance[thisOracle] -= mevu.getMvuStake(thisStruct);
                    stakeForfeit += mevu.getMvuStake(thisStruct);
                }
            }
        
            //for (uint z = 0; z < correctOracles.length; z++) {
                
           // }

            for (uint y = 0; y < correctOracles.length; y++){
               uint reward = ((mevu.getMvuStake(correctStructs[y]) *100)/totalCorrectStake * mevu.getOracleEarnings(eventId))/100;
               
                ethBalance[correctOracles[y]] += reward;
                unlockedEthBalance[correctOracles[y]] += reward;

               
                uint mvuReward = (mevu.getMvuStake(correctStructs[y]) * stakeForfeit)/100;
                uint unlockedMvuReward = mvuReward + mevu.getMvuStake(correctStructs[y]); 
                unlockedMvuBalance[correctOracles[y]] += unlockedMvuReward;
                mvuBalance[correctOracles[y]] += mvuReward;
                
            }             
        }       

    }





     /** @dev Refunds all oracles registered to an event since not enough have registered to vote on the outcome at time of settlement
       *  or because the event has been cancelled.
    
      */ 
    function oracleRefund(uint eventId) private {            
        for (uint i = 0; i < mevu.getStandardEventOraclesLength(eventId); i++) {
            
            for (uint x = 0; x < mevu.getOracleLength(mevu.getStandardEventOracleAt(eventId, i)); x++) {
                bytes32 thisStruct = mevu.getOracleAt(mevu.getStandardEventOracleAt(eventId, i), x);
                if (mevu.getEventId(thisStruct) == eventId){

                    mevu.setOraclePaid(mevu.getOracleAt(mevu.getStandardEventOracleAt(eventId, i), x));
                  
                    unlockedMvuBalance[mevu.getStandardEventOracleAt(eventId, i)] += mevu.getMvuStake(thisStruct);                    
                }
            }
        }
    }

    function cancelEvent (uint eventId) onlyAdmin {
        oracleRefund(eventId);
        for (uint i = 0; i < mevu.getWagersLength(eventId); i++) {
            abortWager(mevu.getEventWager(eventId, i));
        }
    }



     

    /** @dev updates a given voteReady event by locking it and determining the winner based on oracle input.               
     
      */ 
    function updateEvent(uint eventId) private {
        uint teamOneCount = 0;
        uint teamTwoCount = 0;
        uint tieCount = 0;     
        mevu.setLocked(eventId);
        for (uint i = 0; i < mevu.getStandardEventOraclesLength(eventId); i++){
            for (uint x =0; x < mevu.getOracleLength(mevu.getStandardEventOracleAt(eventId, i)); x++){
                bytes32 thisStruct = mevu.getOracleAt(mevu.getStandardEventOracleAt(eventId, i), x);
                if (mevu.getEventId(thisStruct) == eventId){
                    if (mevu.getWinnerVote(thisStruct) == 1){
                        teamOneCount++;
                    }
                    if (mevu.getWinnerVote(thisStruct) == 2){
                        teamTwoCount++;
                    }
                    if (mevu.getWinnerVote(thisStruct) == 0){
                        tieCount++;
                    }              
                }
            }
        }
        if (teamOneCount > teamTwoCount && teamOneCount > tieCount){
           mevu.setWinner(eventId, 1);
        } else {
            if (teamTwoCount > teamOneCount && teamTwoCount > tieCount){
            mevu.setWinner(eventId, 2);
            } else {
                if (tieCount > teamTwoCount && tieCount > teamOneCount){
                    mevu.setWinner(eventId, 3);// Tie
                } else {
                    mevu.setWinner(eventId, 0); // No clear winner
                }
            }
        }
                
    }  
 

     



    function getEthBalance(address user) external view returns (uint) {
        return ethBalance[user];
    }
    function getMvuBalance(address user) external view returns (uint) {
        return mvuBalance[user];
    }

    function getUnlockedEthBalance(address user) external view returns (uint) {
        return unlockedEthBalance[user];
    }

    function getUnlockedMvuBalance(address user) external view returns (uint) {
        return unlockedMvuBalance[user];
    }

    function subEth(address user, uint amount) external onlyOwner {
        ethBalance[user] -= amount;
    }

    function subMvu(address user, uint amount) external onlyOwner {
        mvuBalance[user] -= amount;
    }

     function addEth(address user, uint amount) external onlyOwner {
        ethBalance[user] += amount;
    }

    function addMvu(address user, uint amount) external onlyOwner {
        mvuBalance[user] += amount;
    }

     function subUnlockedMvu(address user, uint amount) external onlyOwner {
        unlockedMvuBalance[user] -= amount;
    }

     function subUnlockedEth(address user, uint amount) external onlyOwner {
        unlockedEthBalance[user] -= amount;
    }

      function addUnlockedMvu(address user, uint amount) external onlyOwner {
        unlockedMvuBalance[user] += amount;
    }

     function addUnlockedEth(address user, uint amount) external onlyOwner {
        unlockedEthBalance[user] += amount;
    }
    
        function subOracleRep(address oracle, uint value) external onlyOwner {
        oracleRep[oracle] -= value;
    }

    function subPlayerRep(address player, uint value) external onlyOwner {
        playerRep[player] -= value;
    }

     function addOracleRep(address oracle, uint value) external onlyOwner {
        oracleRep[oracle] += value;
    }

     function addPlayerRep(address player, uint value) external onlyOwner {
        playerRep[player] += value;
    }



} 