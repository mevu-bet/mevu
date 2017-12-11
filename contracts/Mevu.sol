pragma solidity ^0.4.18; 

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../ethereum-api/usingOraclize.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Wagers.sol";
import "./Rewards.sol";
import "./Oracles.sol";
import "./Lottery.sol";

contract Mevu is Ownable, usingOraclize {

    address mevuWallet;
    Events public events;
    Admin public admin;
    Wagers public wagers;
    OracleVerifier oracleVerif;
    bool public contractPaused = false;
    uint mevuBalance = 0;
    uint standardEventIdCounter = 0;
    uint oraclizeGasLimit = 500000;
    uint oracleServiceFee = 3; //Percent
    mapping (bytes32 => bool) validIds;
    mapping (address => bool) abandoned;
    bytes32[] oracleQueue;  

    event Callback(uint currentTime, string result);

    modifier notPaused() {
        require (!contractPaused);
        _;
    }
    modifier onlyAdmin () {
        require (msg.sender == admin);
        _;
    }

    modifier onlyLottery () {
        require (msg.sender == lottery);
        _;
    }

    modifier onlyOraclesContract () {
        require (msg.sender == oracles);
        _;
    }

     modifier notPaused() {
        require (!contractPaused);
        _;
    }

    modifier onlyPaused() {
        require (contractPaused);
        _;
    }

    modifier onlyMaker(bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId));
        _;
    }
    
    modifier onlyTaker(bytes32 wagerId) {
        require (msg.sender == wagers.getTaker(wagerId));
        _;
    }   
    
    modifier onlyOracle (bytes32 oracleId) {
        bool oracle = false;
        for (uint i = 0; i < oracles.getOracleLength(msg.sender); i++) {
            if (oracles.getOracleAt(msg.sender, i) == oracleId) {
                oracle = true;
            }
        }
        if (oracle) {
            _;
        }
    }
    
    
    modifier eventUnlocked(uint256 eventId){
        require (!events.getLocked(eventId));
        _;
    }

    modifier wagerUnlocked (bytes32 wagerId) {
        require (!wagers.getLocked(wagerId));
        _;
    }
    
    modifier notTaken (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) == address(0));
        _;
    }    
    
    modifier mustBeVoteReady(uint256 eventId) {
        require (events.getVoteReady(eventId));
        _;           
    }  

    modifier requireMinWager() {
        require (msg.value >= admin.getMinWagerAmount());
        _;
    }
    
    modifier checkBalance (uint256 wagerValue) {
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= wagerValue);
        _;
    }   

    modifier mustBeCorrectValue(bytes32 wagerId) {
        require (msg.value == wagers.getOrigValue(wagerId) / (wagers.getOdds(wagerId) / 100));
        _;
    }

    modifier onlyVerified() {
        require (oracleVerif.checkVerification(msg.sender));
        _;
    }
    
    modifier onlyOracle (bytes32 oracleId) {
        bool oracle = false;
        for (uint i = 0; i < Mevu(mevuContract).getOracleLength(msg.sender); i++) {
            if (Mevu(mevuContract).getOracleAt(msg.sender, i) == oracleId) {
                oracle = true;
            }
        }
        if (oracle){
            _;
        }
    }

    // Constructor 
    function Mevu ()  payable { 
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);               
        mevuWallet = msg.sender;
        events = deployEventsContract();
        bytes32 queryId = oraclize_query(100, "URL", "", oraclizeGasLimit);
        validIds[queryId] = true;
        wagers = deployWagersContract();
        oracleVerif = deployOracleVerifier();
        // deployOracles();
        // deployRewards();
        // deployLottery();
        admin = deployAdminContract();      
    }

    function deployEventsContract () internal returns (Events) {
        return new Events();
    }

    function deployAdminContract () internal returns (Admin) {
        return new Admin();
    }

    function deployWagersContract () internal returns (Wager) {
        return new Wager();
    }

    function deployOracleVerifContract () internal returns (OracleVerifer) {
        return new OracleVerifier();
    }

  
    function __callback (bytes32 myid, string result) notPaused {        
        if (!validIds[myid]) revert;
        if (msg.sender != oraclize_cbAddress()) revert;
       
       
        if (randomNumRequired){        
            uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
            uint randomNumber = uint(sha3(result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
            randomNumRequired = false;   
            address potentialWinner = oracleList[randomNumber]; 
            payoutLottery(potentialWinner);
        } else {   
            // Go through oracle queue and settle wagers with voteReady events, oracles recieve higher fee
            Rewards(rewardsContract).oracleSettle();       
            // Make recently completed events voteReady
            events.voteReady();            
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            bytes32 queryId = oraclize_query(Admin(adminContract).getCallbackInterval(), "URL", "", Admin(adminContract).getCallbackGasLimit());
            validIds[queryId] = true;
        }        
        Lottery(lotteryContract).checkLottery();
    }

 
    

    function setMevuWallet (address newAddress) onlyOwner {
        mevuWallet = newAddress;       
    }

    

    /** @dev Creates a new Standard event struct for users to bet on and adds it to the standardEvents mapping.
      * @param name The name of the event to be diplayed.
      * @param startTime The date and time the event begins in unix epoch.
      * @param duration The length of the event in seconds.
      * @param eventType The sport or event category, eg. Hockey, MMA, Politics etc...
      * @param teamOne The name of one of the participants, eg. Toronto Maple Leafs, Georges St-Pierre, Justin Trudeau.
      * @param teamTwo The name of teamOne's opposition.     
      */
    function makeStandardEvent(
        bytes32 name,
        uint256 startTime,
        uint256 duration,
        bytes32 eventType,
        bytes32 teamOne,
        bytes32 teamTwo
    )
        onlyOwner            
        returns (bytes32) 
    {
        bytes32 id = keccak256(name); 
        events.makeStandardEvent(   id,                                        
                                    name,
                                    startTime,
                                    duration,
                                    eventType,
                                    teamOne,
                                    teamTwo);
        return id;                      
    }

    function updateStandardEvent(
        bytes32 eventId,
        uint256 newStartTime,
        uint256 newDuration,
        bytes32 newTeamOne,
        bytes32 newTeamTwo
    ) 
        external 
        onlyOwner 
    {
        events.updateStandardEvent(eventId, newStartTime, newDuration, newTeamOne, newTeamTwo);             
    }
   

    function cancelStandardEvent (bytes32 eventId) onlyOwner {
        events.cancelStandardEvent(eventId);       
    }

    /** @dev Creates a new Standard wager for a user to take and adds it to the standardWagers mapping.
      * @param id sha3 hash of the msg.sender concat timestamp.
      * @param eventId int id for the standard event the wager is based on.
      * @param odds decimal of maker chosen odds * 100.         
      */
    function makeWager(
        bytes32 wagerId,
        uint value,       
        uint eventId,
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
        uint256 winningValue = value + (value / (odds/100));       
        wagers.makeWager(wagerId, value, winningValue, eventId, maker, makerChoice, takerChoice, odds);     
        events.addWager(eventId, wagerId);
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));     
    }

    function cancelWager (
        bytes32 wagerId, 
        bool withdraw
    ) 
        onlyMaker(wagerId)
        notPaused
        notTaken(wagerId)
        wagerUnlocked(wagerId) 
    {          
        wagers.setLocked(wagerId);
        wagers.setSettled(wagerId);                   
        if (withdraw) {
            rewards.subEth(msg.sender, thisWager.value);                
            msg.sender.transfer (wagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, thisWager.value);
        }            
    }

    function requestWagerCancel(bytes32 wagerId) 
        mustBeTaken(wagerId) 
        notSettled(wagerId) 
    {       
        if (msg.sender == wagers.getTaker(wagerId)) {
            if (wagers.getMakerCancelRequest(wagerId)) {            
                wagers.setSettled(wagerId);                
                rewards.addUnlockedEth(wagers.getMaker(wagerId), wagers.getOrigValue(wagerId)); 
                rewards.addUnlockedEth(wagers.getTaker(wagerId),  (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
            } else {
                wagers.setTakerCancelRequest(wagerId);
            }
        }
        if (msg.sender ==  wagers.getMaker(wagerId)) {
            if (wagers.getTakerCancelRequest(wagerId)) {            
                wagers.setSettled(wagerId);              
                rewards.addUnlockedEth(wagers.getMaker(wagerId), wagers.getOrigValue(wagerId));
                rewards.addUnlockedEth(wagers.getTaker(wagerId),  (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
            } else {
                wagers.setMakerCancelRequest(wagerId);
            }
        }        
    }  

    function abandonContract() external onlyPaused {
        require(!abandoned[msg.sender]);
        abandoned[msg.sender] = true;
        uint ethBalance = rewards.getEthBalance(msg.sender);
        uint mvuBalance = rewards.getMvuBalance(msg.sender);
        if (ethBalance > 0) {
            msg.sender.transfer(ethBalance);           
        }
        if (mvuBalance > 0) {
            mvuToken.transfer(msg.sender, mvuBalance);
        }
    } 
    
    
    //  function updateWager (
    //     bytes32 wagerId,
    //     uint eventId, 
    //     uint odds, 
    //     uint256 value,
    //     uint makerChoice) 
    //     onlyMaker(wagerId) 
    //     notPaused
    //     notTaken(wagerId)
    //     wagerUnlocked(wagerId)
    //     eventUnlocked(eventId)
    //     checkBalance(value)
    //     payable {
    //         bool newEvent = false;
           
    //         StandardWager thisWager = standardWagers[wagerId];
    //         if (thisWager.eventId != eventId) {
    //             newEvent = true;
    //         }
    //         Rewards(rewardsContract).addUnlockedEth(msg.sender, thisWager.value);
    //         Rewards(rewardsContract).subUnlockedEth(msg.sender, value);
    //         Rewards(rewardsContract).addEth(msg.sender, msg.value); 
    //         thisWager.eventId = eventId;
    //         thisWager.odds = odds;
    //         thisWager.value = value;
    //         thisWager.makerChoice = makerChoice;
    //         standardWagers[wagerId] = thisWager;
    //         if  (newEvent) {
    //             standardEvents[eventId].wagers.push(wagerId);
    //         }
    // }


     function withdraw(
        uint eth,
        uint mvu
    )
        external
        notPaused 
    { 
        if (rewards.getUnlockedEthBalance(msg.sender) >= eth) {
            rewards.subUnlockedEth(msg.sender, eth);
            rewards.subEth(msg.sender, eth);
            msg.sender.transfer(eth);
        }
        if (rewards.getUnlockedMvuBalance(msg.sender) >= mvu) {
            rewards.subUnlockedMvu(msg.sender, mvu);
            rewards.subMvu(msg.sender, mvu);
            mvuToken.transfer (msg.sender, mvu);
        }  
    } 
    
     /** @dev Takes a listed wager for a user -- adds address to StandardWager struct.
      * @param id sha3 hash of the msg.sender concat timestamp.         
      */
    function takeStandardWager (
        bytes32 id      
    )   
        eventUnlocked(wagers.getEventId(id))
        wagerUnlocked(id)
        mustBeCorrectValue(id)
        notPaused
        payable 
    {
        address taker = msg.sender;
        wagers.takeWager(id, taker);        
        rewards.addEth(msg.sender, msg.value);      
    }    
    
    /** @dev Enters the makers vote for who actually won after the event is over.               
      * @param wagerId bytes32 id for the wager.
      * @param winnerVote number representing who the creator thinks won the match         
      */
    function submitMakerVote (      
        bytes32 wagerId,
        uint winnerVote
    ) 
        onlyMaker(wagerId) 
        mustBeVoteReady(wagers.getEventId(wagerId))
        notPaused 
    {
        bytes32 eventId = wagers.getEventId(wagerId);        
        wagers.setMakerWinVote (wagerId, winnerVote);
        uint eventWinner = events.getWinner(eventId);
        
        if (eventWinner != 0 && eventWinner != 3) {
            lateSettle(wagerId, eventWinner);
            lateSettledPayout(wagerId);    
        } else {
            if (events.getCancelled(eventId) || events.getWinner(eventId) == 3) {
                rewards.abortWager(wagerId);                
            } else {
                if (wagers.getTakerWinVote(wagerId) != 0 && events.getVoteReady(eventId)) {
                    wagers.settle(wagerId);
                }
            }       
        }       
    }


     function submitTakerVote (      
        bytes32 wagerId,
        uint winnerVote
    ) 
        onlyTaker(wagerId) 
        mustBeVoteReady(wagers.getEventId(wagerId))
        notPaused 
    {
        bytes32 eventId = wagers.getEventId(wagerId);        
        wagers.setTakerWinVote (wagerId, winnerVote);
        uint eventWinner = events.getWinner(eventId);
        
        if (eventWinner != 0 && eventWinner != 3) {
            lateSettle(wagerId, eventWinner);
            lateSettledPayout(wagerId);    
        } else {
            if (events.getCancelled(eventId) || events.getWinner(eventId) == 3) {
                rewards.abortWager(wagerId);                
            } else {
                if (wagers.getMakerWinVote(wagerId) != 0 && events.getVoteReady(eventId)) {
                    wagers.settle(wagerId);
                }
            }       
        }       
    }


     /** @dev Settles the wager if both the maker and taker have voted, pays out if they agree, otherwise they need to wait for oracle settlement.               
       * @param wagerId bytes32 id for the wager.         
       */
    function settle(bytes32 wagerId) internal {
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getMaker(wagerId);
        if (wagers.getMakerWinVote(wagerId) == wagers.getTakerWinVote(wagerId)) {
            if (wagers.getMakerWinVote(wagerId) == wagers.getMakerChoice(wagerId)) {
                Mevu(mevuContract).setWagerWinner(wagerId, maker);
                rewards.addEth(maker, wagers.getWinningValue(wagerId) - wagers.getValue(wagerId));
                rewards.subEth(taker, wagers.getWinningValue(wagerId) - wagers.getValue(wagerId));
            } else {
                if (wagers.getMakerWinVote(wagerId) == 3) {
                    wagers.setWinner(wagerId, address(0));                    
                } else {
                    wagers.setWinner(wagerId, taker);
                    rewards.addEth(maker, wagers.getValue(wagerId));
                    rewards.subEth(taker, wagers.getValue(wagerId));
                }
            }
            payout(wagerId, maker, taker);
        } else {
            addToOracleQueue(wagerId);
        }
      
    }


    /** @dev Pays out the wager if both the maker and taker have agreed, otherwise they need to wait for oracle settlement.               
       * @param wagerId bytes32 id for the wager.         
       */
     function payout(bytes32 wagerId, address maker, address taker) internal {  
         if (!wagers.getSettled(wagerId)){
            wagers.setSettled(wagerId);
             if (wagers.getWinner(wagerId) == address(0)) { //Tie               
                transferEthFromMevu(maker, wagers.getOrigValue(wagerId));
                transferEthFromMevu(taker, wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId));     
             } else {
                uint payoutValue = wagers.getWinningValue(wagerId); 
                uint fee = (payoutValue/100) * 2; // Sevice fee is 2 percent
                addMevuBalance(3*(fee/4));
                rewards.subEth(wagers.getWinner(wagerId), payoutValue);
                payoutValue -= fee;
                addLotteryBalance(fee/8);
                uint oracleFee = fee/8;                         
                transferEthFromMevu(wagers.getWinner(wagerId), payoutValue);  
                events.addOracleEarnings(wagers.getEventId(wagerId), oracleFee);              
            }                             
            rewards.addPlayerRep(maker, 25);
            rewards.addPlayerRep(taker, 25);
            wagers.setLocked(wagerId);
        }       
    }

    function lateSettle (bytes32 wagerId, uint eventWinner) onlyMevuContract {
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        if (wagers.getMakerChoice(wagerId) == eventWinner) {
            wagers.setWinner(wagerId, maker);               
        } else {     
            wagers.setWinner(wagerId, taker);  
        }             
    }
    
  /** @dev Pays out the wager after oracle settlement.               
    * @param wagerId bytes32 id for the wager.         
    */
    function lateSettledPayout(bytes32 wagerId) private {
        
        if (!wagers.getSettled(wagerId)) {
            uint origValue = wagers.getOrigValue(wagerId);
            uint winningValue = wagers.getWinningValue(wagerId);           
            uint payoutValue = winningValue;
            uint fee = (payoutValue/100) * oracleServiceFee;
            addMevuBalance(fee/2);            
            addLotteryBalance(fee/12);
            payoutValue -= fee;           
            uint oracleFee = (fee/12) + (fee/3);
            addLotteryBalance(oracleFee); // Too late to reward oracles directly for this wager, fee added to oracle lottery
            address maker = wagers.getMaker(wagerId);
            address taker = wagers.getTaker(wagerId);
            wagers.setSettle(wagerId);
            wagers.setLock(wagerId);            
            if (wagers.getWinner(wagerId) == maker) { // Maker won
                rewards.addUnlockedEth(maker, payoutValue);
                rewards.addEth(maker, (winningValue - origValue));
            } else { //Taker won
               rewards.addUnlockedEth(taker, payoutValue);
               rewards.addEth(taker, origValue);
            }           
        }
    }

     /** @dev Registers a user as an Oracle for the chosen event. Before being able to register the user must
      * allow the contract to move their MVU through the Token contract.      
      * @param oracleId bytes32 id for the oracle mapping to get struct with info.            
      * @param eventId int id for the standard event the oracle is registered for.
      * @param mvuStake Amount of mvu (in lowest base unit) staked.         
      */
    function registerOracle (        
        bytes32 oracleId,
        uint eventId,
        uint mvuStake,
        uint winnerVote
    ) 
        eventUnlocked(eventId) 
        onlyVerified
        notPaused
        mustBeVoteReady(eventId) 
    {
        require (sha3(strConcat(toString(msg.sender),  bytes32ToString(uintToBytes(eventId)))) == oracleId);       
        require(mvuStake >= admin.getMinOracleStake()); 
           
        if (Mevu(mevuContract).getMvuStake(oracleId) == 0) {
            if (Mevu(mevuContract).getOracleLength(msg.sender) == 0) {
                Mevu(mevuContract).addToOracleList(msg.sender);
            }
            transferTokensToMevu(msg.sender, mvuStake);             
            oracles.createOracle(eventId, mvuStake, oracleId, winnerVote, false);               
            rewards.addMvu(msg.sender, mvuStake);
            events.addOracle(eventId, msg.sender, mvuStake);
               
        }        
    }  
     
    
    
    /** @dev Unregisters a user as an Oracle for the chosen event.      
      * @param oracleId bytes32 id for the oracle mapping to get struct with info.         
      */
    function unregisterOracle (bytes32 oracleId)
        onlyOracle(oracleId)
        eventUnlocked(oracles.getEventId(oracleId))
        notPaused 
    {
        uint eventId = oracles.getEventId(oracleId);
        uint mvuStake = oracles.getMvuStake(oracleId);            
        events.subTotalOracleStake(eventId, mvuStake);          
        if (rewards.getMvuBalance(msg.sender) >= mvuStake){
            rewards.subMvu(msg.sender, mvuStake);
            transferTokensFromMevu (msg.sender, mvuStake);               
        }            

        oracles.removeOracle(msg.sender, eventId, oracleId);            
              
        for (uint256 y = 0; y < Mevu(mevuContract).getStandardEventLength(); y++){
            if (y == eventId) {
                for (uint256 x = 0; x < Mevu(mevuContract).getStandardEventOraclesLength(y); x++){
                    address thisOracle = Mevu(mevuContract).getStandardEventOracleAt(y, x);                       
                    if(thisOracle == msg.sender) {                          
                        events.removeOracleFromEvent (y, x);                            
                    } 
                }
            }        
        }       
    }

    /** @dev Pay winners of wagers and alter rep of winners and losers, refund both if winner = 0
      * @param thisWager the standard wager currently being paid out.
      * @param thisEvent the StandardWagerEvent that is associated with thisWager.           
      */ 
    function playerRewards(bytes32 thisWager, bytes32 thisEvent) private {
      
        if (events.getWinner(thisEvent) != 0){
            if (events.getWinner(thisEvent) == 3){
                if (wagers.getMakerWinVote(thisWager) == 3) {
                    rewards.addPlayerRep(wagers.getMaker(thisWager), wagers.getWinningValue(thisWager));
                    rewards.subPlayerRep(wagers.getTaker(thisWager), wagers.getWinningValue(thisWager));                    
                } else {
                    rewards.subPlayerRep(wagers.getMaker(thisWager), wagers.getWinningValue(thisWager));
                    rewards.addPlayerRep(wagers.getTaker(thisWager), wagers.getWinningValue(thisWager));                    
                }              
                abortWager(thisWager);
            } else {
                rewards.addPlayerRep(wagers.getWinner(thisWager), wagers.getWinningValue(thisWager));
                rewards.subPlayerRep(wagers.getLoser(thisWager), wagers.getWinningValue(thisWager));                
                oracleSettledPayout(thisWager);
            }
        } else {
            abortWager(thisWager);
        }         
    }

    

    
    /** @dev Pays out the wager after oracle settlement.               
      * @param wagerId bytes32 id for the wager.         
      */
    function oracleSettledPayout(bytes32 wagerId) private {
        
        if (!wagers.getSettled(wagerId)) {            
            uint payoutValue = wagers.getWinningValue(wagerId);
            uint fee = (payoutValue/100) * oracleServiceFee;
            addMevuBalance(fee/2);            
            addLotteryBalance(fee/12);
            payoutValue -= fee;           
            uint oracleFee = (fee/12) + (fee/3);
            wagers.setSettled(wagerId);
            
            if (wagers.getWinner(wagerId) == wagers.getMaker(wagerId)) { // Maker won
                rewards.addUnlockedEth(wagers.getMaker(wagerId), payoutValue);
                rewards.addEth(wagers.getMaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
           
            } else { //Taker won
                rewards.addUnlockedEth(wagers.getTaker(wagerId), payoutValue);
                rewards.addEth(wagers.getMaker(wagerId),  wagers.getOrigValue(wagerId));          
             
            }            
            events.addOracleEarnings(wagers.getEventId(wagerId), oracleFee);
        }
    }

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
       *  been cancelled, refunds all eth.               
       * @param wagerId bytes32 wagerId of the wager to abort.  
       */ 
    function abortWager(bytes32 wagerId) external onlyOwner {
        
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));       
        
        if (taker != address(0)) {         
            rewards.addUnlockedEth(taker, (mevu.getWinningValue(wagerId) - mevu.getOrigValue(wagerId)));
        } 
            
    }


     /** @dev Settle and facilitate payout of wagers needing oracle settlement.           
      */ 
    function oracleSettle() internal {
     
        for (uint a = 0; a < events.getActiveEventsLength(); a++) {
            if (events.getVoteReady(a) && !events.getLocked(a)) {
                if (events.getStandardEventOraclesLength(a) >= admin.getMinOracleNum()) { 
                   // if (mevu.getStandardEventOracleVotesNum(a) >= mevu.getMinOracleNum()) {     
                        //checkStakeEquity(a);
                        updateEvent(a);                        
                        oracleRewards(a); 
                   // } else {
                    //    oracleRedistribute(a);
                   // }
                } else {
                    events.setEventWinner(a, 0);
                    events.setEventLocked(a);
                    oracleRefund(a);
                } 
            }
        }                 
        for (uint i = 0; i <  mevu.getOracleQueueLength(); i++){
            uint thisEvent = mevu.getWagerEventId(mevu.getOracleQueueAt(i));      
           
            // Determine winner
            if (mevu.getMakerChoice(mevu.getOracleQueueAt(i)) == mevu.getWinner(thisEvent)) {
               mevu.setWagerWinner(mevu.getOracleQueueAt(i), mevu.getMaker(mevu.getOracleQueueAt(i)));
                mevu.setWagerLoser(mevu.getOracleQueueAt(i), mevu.getTaker(mevu.getOracleQueueAt(i)));
            } else {
                if (mevu.getTakerChoice(mevu.getOracleQueueAt(i)) == mevu.getWinner(thisEvent)){ 
                   mevu.setWagerWinner(mevu.getOracleQueueAt(i), mevu.getTaker(mevu.getOracleQueueAt(i)));
                mevu.setWagerLoser(mevu.getOracleQueueAt(i), mevu.getMaker(mevu.getOracleQueueAt(i)));
                } else {   
                    // Tie or no clear winner
                    mevu.setWagerWinner(mevu.getOracleQueueAt(i), address(0));
                mevu.setWagerLoser(mevu.getOracleQueueAt(i), address(0));
                }
            }
            // punish loser with bad rep for disagreeing         
            // pay and reward winner with rep
            playerRewards(mevu.getOracleQueueAt(i), thisEvent);
        }     
        //Set oracleQueue back to nothing to be re-filled tomorrow.
        mevu.deleteOracleQueue();
        
    }     

  
    
    function pauseContract() 
        external
        onlyMevu {
        contractPaused = true;    
    }

    function restartContract() 
        external 
        onlyMevu {            
        contractPaused = false;
        bytes32 queryId = oraclize_query(Admin(adminContract).getCallbackInterval(), "URL", "", Admin(adminContract).getCallbackGasLimit());          
        validIds[queryId] = true;      
    }     

    function addToOracleList (address oracle) {
        oracleList.push(oracle);
    }

    function addToOracleQueue (bytes32 wager) {
        oracleQueue.push(wager);
    }  

    function getOracleQueueAt(uint index) returns (bytes32) {
        return oracleQueue[index];
    }
    
    function getOracleQueueLength() returns (uint) {
        return oracleQueue.length;
    }    

    function deleteOracleQueue() {
        delete oracleQueue;
    }    

    function addMevuBalance (uint amount) internal {
        mevuBalance += amount;
    }

    function addLotteryBalance (uint amount) internal {
        lotteryBalance += amount;
    }    

    function getContractPaused() constant returns (bool) {
        return contractPaused;
    }     

    function getOracleFee () constant returns (uint256) {
        return oracleServiceFee;
    }

    function transferTokensToMevu (address oracle, uint mvuStake) internal {
        mvuToken.transferFrom(oracle, this, mvuStake);       
    }

    function transferTokensFromMevu (address oracle, uint mvuStake) internal {
        mvuToken.transfer(oracle, mvuStake);       
    }

    function transferEthFromMevu (address recipient, uint amount) internal {
        recipient.transfer(amount);
    }   
  
    function addMonth () onlyLottery {
        newMonth += monthSeconds;
    }
  
   
    function getNewMonth () constant returns (uint256) {
        return newMonth;
    }

    function makeOraclizeQuery (string engine, string query) onlyLottery {
        oraclize_query (engine, query, Admin(adminContract).getCallbackGasLimit());
    } 
    
} 






