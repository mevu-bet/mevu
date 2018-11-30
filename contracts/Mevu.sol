pragma solidity ^0.4.18;
import "./AuthorityGranter.sol";
import "../ethereum-api/oraclizeAPI.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Wagers.sol";
import "./Rewards.sol";
import "./Oracles.sol";
//import "./MvuToken.sol";
import "../zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

contract Mevu is AuthorityGranter, usingOraclize {

    address private mevuWallet;
    Events private events;
    Admin private admin;
    Oracles private oracles;
    Rewards private rewards;
    MintableToken private mvuToken;
    Wagers private wagers;

    bool public contractPaused = false;
    bool private randomNumRequired = false;
    int private lastIteratedIndex = -1;
    uint public mevuBalance = 0;
    uint public lotteryBalance = 0;

    uint private oracleServiceFee = 3; //Percent

    uint public nextMonth;
    uint public lastMonth;
    uint private monthSeconds = 2592000;
    uint public playerFunds;

    mapping (bytes32 => bool) private validIds;
    mapping (address => bool) private abandoned;

    mapping (address => uint) private lastLotteryEntryTimes;
    address[] private lotteryEntrants;


    event NewOraclizeQuery (string description);
    event OraclizeQueryResponse (string result);
    event LotteryPotIncreased(uint addedAmount);
    event ReceivedRandomNumber(uint number);
    event OracleEnteredLottery(address entrant);
    event Aborted (bytes32 wagerId);

    modifier notPaused() {
        require (!contractPaused);
        _;
    }

    modifier onlyPaused() {
        require (contractPaused);
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }

    // Constructor
    constructor () payable {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        lastMonth = 1; // Last entries default to 0, set the last month to 1 to allow people to enter the first lottery
        nextMonth = block.timestamp + monthSeconds;
        mevuWallet = msg.sender;
    }

    function () payable {

    }

    function setEventsContract (address thisAddr) external onlyOwner { events = Events(thisAddr); }

    function setOraclesContract (address thisAddr) external onlyOwner { oracles = Oracles(thisAddr); }

    function setRewardsContract   (address thisAddr) external onlyOwner { rewards = Rewards(thisAddr); }

    function setAdminContract (address thisAddr) external onlyOwner { admin = Admin(thisAddr); }

    function setWagersContract (address thisAddr) external onlyOwner { wagers = Wagers(thisAddr); }

    function setMvuTokenContract (address thisAddr) external onlyOwner { mvuToken = MintableToken(thisAddr); }

    function setMevuWallet (address newAddress) external onlyOwner {
        mevuWallet = newAddress;
    }

    function abandonContract() external onlyPaused {
        require(!abandoned[msg.sender]);
        abandoned[msg.sender] = true;
        uint ethBalance =  rewards.getEthBalance(msg.sender);
        uint mvuBalance = rewards.getMvuBalance(msg.sender);
        playerFunds -= ethBalance;
        if (ethBalance > 0) {
            msg.sender.transfer(ethBalance);
        }
        if (mvuBalance > 0) {
            mvuToken.transfer(msg.sender, mvuBalance);
        }
    }

    function getLotteryPot() external view returns (uint) {
        return lotteryBalance;
    }

    function getLotteryEntrantCount() external view returns (uint) {
        return lotteryEntrants.length;
    }

    function enterLottery() external returns (bool) {
        require(allowedToWin(msg.sender));
        // Users may not enter more than once
        require(lastLotteryEntryTimes[msg.sender] < lastMonth);

        // Keep track of most recent entry to prevent multiple entries
        lastLotteryEntryTimes[msg.sender] = block.timestamp;
        lotteryEntrants.push(msg.sender);

        emit OracleEnteredLottery(msg.sender);

        return true;
    }

    /** @dev Runs lottery
      */
    function runLottery() {
        require(block.timestamp > nextMonth);
        require(lotteryEntrants.length > 0);
        bytes32 queryId = oraclize_query("WolframAlpha", strConcat("random number between 0 and ", uint2str(lotteryEntrants.length - 1)));
                        //oraclize_newRandomDSQuery(/* Delay */ 0, /* Random Bytes */ 7, /* Callback Gas */ admin.getCallbackGasLimit());
        emit NewOraclizeQuery("Getting random number for picking the lottery winner");
        validIds[queryId] = true;
    }

    function __callback (bytes32 _queryId, string _result) public {
        emit OraclizeQueryResponse(_result);
        require(validIds[_queryId]);
        require(msg.sender == oraclize_cbAddress());

        // Invalidate the query ID so it cannot be reused
        validIds[_queryId] = false;

        uint maxRange = lotteryEntrants.length; // The max number should be no more than the number of entrants - 1
        uint randomNumber = parseInt(_result) % maxRange;
        emit ReceivedRandomNumber(randomNumber);

        payoutLottery(randomNumber);
    }

    /** @dev Pays out the monthly lottery balance to a random oracle.
      */
    function payoutLottery(uint winnerIndex) notPaused internal {
        address potentialWinner = lotteryEntrants[winnerIndex];
        if (allowedToWin(potentialWinner)) {
            uint thisWin = lotteryBalance;
            lotteryEntrants.length = 0;
            addMonth();
            lotteryBalance = 0;
            potentialWinner.transfer(thisWin);
        } else {
            // Winner is no longer allowed to win
            // Swap winner with last entrant and then decrease the size of the list (don't need to actually retain old entrant)
            lotteryEntrants[winnerIndex] = lotteryEntrants[lotteryEntrants.length - 1];
            lotteryEntrants.length = lotteryEntrants.length - 1;
            require(oracles.getOracleListLength() > 0);
            runLottery();
        }
    }

    function allowedToWin (address potentialWinner) internal view returns (bool) {
        return mvuToken.balanceOf(potentialWinner) > 0
        && block.timestamp - events.getEndTime(oracles.getLastEventOraclized(potentialWinner)) < admin.getMaxOracleInterval()
        && rewards.getOracleRep(potentialWinner) > 0
        && rewards.getPlayerRep(potentialWinner) >= 0;
    }

    // Players should call this when an event has been cancelled after they have made a wager
    function playerRefund (bytes32 wagerId) external  onlyBettor(wagerId) {
        require (events.getCancelled(wagers.getEventId(wagerId)));
        require (!wagers.getRefund(msg.sender, wagerId));
        wagers.setRefund(msg.sender, wagerId);
        address maker = wagers.getMaker(wagerId);
        wagers.setSettled(wagerId);
        if(msg.sender == maker) {
            rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }
    }

    function pauseContract()
    external
    onlyOwner
    {
        contractPaused = true;
    }

    // function restartContract(uint secondsFromNow)
    //     external
    //     onlyOwner
    //     payable
    // {
    //     contractPaused = false;
    //     //lastIteratedIndex = int(events.getActiveEventsLength()-1);
    //     NewOraclizeQuery("Starting contract!");
    //     bytes32 queryId = oraclize_query(secondsFromNow, "URL", "", admin.getCallbackGasLimit());
    //     validIds[queryId] = true;
    // }

    function mevuWithdraw (uint amount) external onlyOwner {
        require(mevuBalance >= amount);
        mevuWallet.transfer(amount);
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
        msg.sender.transfer(eth);
    }

    function addMevuBalance (uint amount) external onlyAuth { mevuBalance += amount; }

    // function addEventToIterator () external onlyAuth {
    //     lastIteratedIndex++;
    // }

    function addLotteryBalance (uint amount) external onlyAuth {
        lotteryBalance += amount;
        emit LotteryPotIncreased(amount);
    }

    function addToPlayerFunds (uint amount) external onlyAuth { playerFunds += amount; }

    function subFromPlayerFunds (uint amount) external onlyAuth { playerFunds -= amount; }

    function transferEth (address recipient, uint amount) external onlyAuth { recipient.transfer(amount); }

    function getContractPaused() external view returns (bool) { return contractPaused; }

    function getOracleFee () external view returns (uint256) { return oracleServiceFee; }

    function transferTokensToMevu (address oracle, uint mvuStake) internal { mvuToken.transferFrom(oracle, this, mvuStake); }

    function transferTokensFromMevu (address oracle, uint mvuStake) external onlyAuth { mvuToken.transfer(oracle, mvuStake); }

    function addMonth () internal {
        lastMonth = nextMonth;
        nextMonth += monthSeconds;
    }

    function getNextMonth () internal view returns (uint256) { return nextMonth; }

    function uintToBytes(uint v) internal view returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function bytes32ToString (bytes32 data) internal view returns (string) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
 *  been cancelled, refunds all eth.
 *  @param wagerId bytes32 wagerId of the wager to abort.
 */
    function abortWager(bytes32 wagerId) onlyBettor(wagerId) external {

        require (events.getCancelled(wagers.getEventId(wagerId)));

        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));

        if (taker != address(0)) {
            rewards.addUnlockedEth(taker, (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }
        emit Aborted(wagerId);
    }

}