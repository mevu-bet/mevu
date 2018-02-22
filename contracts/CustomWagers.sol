pragma solidity 0.4.18;
//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";
contract CustomWagers is AuthorityGranter {
        
    struct Wager {
        uint endTime;            
        uint origValue;
        uint winningValue;        
        uint makerChoice;
        uint takerChoice;
        uint odds;
        uint makerWinnerVote;
        uint takerWinnerVote;
        address maker;
        address taker;
        address judge;        
        address winner; 
        address loser;
        bool makerCancelRequest;
        bool takerCancelRequest;       
        bool settled;        
    }

    mapping (bytes32 => bool) private cancelled;   
    mapping (bytes32 => Wager) private wagersMap;
    mapping (address => mapping (bytes32 => bool)) private recdRefund;
    mapping  (bytes32 => uint) private judgesVote;

    modifier onlyAuth () {
        require(isAuthorized[msg.sender]);               
                _;
    }

    function grantAuthority (address nowAuthorized) external onlyOwner {
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) external onlyOwner {
        isAuthorized[unauthorized] = false;
    }
    
    function makeWager (
        bytes32 wagerId,
        uint endTime,          
        uint origValue,
        uint winningValue,        
        uint makerChoice,
        uint takerChoice,
        uint odds,
        uint makerWinnerVote,
        uint takerWinnerVote,
        address maker,
        address judge
        )
            external
            onlyAuth             
        {
        Wager memory thisWager = Wager (endTime,
                                        origValue,
                                        winningValue,
                                        makerChoice,
                                        takerChoice,
                                        odds,
                                        makerWinnerVote,
                                        takerWinnerVote,
                                        maker,
                                        address(0),
                                        judge,
                                        address(0),
                                        address(0),
                                        false,
                                        false,                                        
                                        false);
        wagersMap[wagerId] = thisWager;       
    }

    function setCancelled (bytes32 bet) external onlyAuth {
        cancelled[bet] = true;
    }    

    function setSettled (bytes32 wagerId) external onlyAuth {
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

    function setMakerCancelRequest (bytes32 id) external onlyAuth {
        wagersMap[id].makerCancelRequest = true;
    }

    function setTakerCancelRequest (bytes32 id) external onlyAuth {
        wagersMap[id].takerCancelRequest = true;
    }

    function setTaker (bytes32 wagerId, address taker) external onlyAuth {
        wagersMap[wagerId].taker = taker;
    }

    function setWinner (bytes32 id, address winner) external onlyAuth {
        wagersMap[id].winner = winner;        
    }

    function setJudgesVote (bytes32 id, uint vote) external onlyAuth {
        judgesVote[id] = vote;
    }

    function setLoser (bytes32 id, address loser) external onlyAuth {
        wagersMap[id].loser = loser;
    }

    function setWinningValue (bytes32 wagerId, uint value) external onlyAuth {
        wagersMap[wagerId].winningValue = value;
    }

    function getCancelled (bytes32 bet) external view returns (bool) {
        return cancelled[bet];
    }

    function getEndTime (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].endTime;
    }   

    function getLocked (bytes32 id) external view returns (bool) {
        if (wagersMap[id].taker == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function getSettled (bytes32 id) external view returns (bool) {
        return wagersMap[id].settled;
    }

    function getMaker(bytes32 id) external view returns (address) {
        return wagersMap[id].maker;
    }

    function getTaker(bytes32 id) external view returns (address) {
        return wagersMap[id].taker;
    }

    function getMakerChoice (bytes32 id) external view returns (uint) {
        return wagersMap[id].makerChoice;
    }

    function getTakerChoice (bytes32 id) external view returns (uint) {
        return wagersMap[id].takerChoice;
    }

    function getMakerCancelRequest (bytes32 id) external view returns (bool) {
        return wagersMap[id].makerCancelRequest;
    }

    function getTakerCancelRequest (bytes32 id) external view returns (bool) {
        return wagersMap[id].takerCancelRequest;
    }

    function getMakerWinVote (bytes32 id) external view returns (uint) {
        return wagersMap[id].makerWinnerVote;
    }

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) {
        return recdRefund[bettor][wagerId];
    }

    function getTakerWinVote (bytes32 id) external view returns (uint) {
        return wagersMap[id].takerWinnerVote;
    }

    function getOdds (bytes32 id) external view returns (uint) {
        return wagersMap[id].odds;
    }

    function getOrigValue (bytes32 id) external view returns (uint) {
        return wagersMap[id].origValue;
    }

    function getWinningValue (bytes32 id) external view returns (uint) {
        return wagersMap[id].winningValue;
    }

    function getWinner (bytes32 id) external view returns (address) {
        return wagersMap[id].winner;
    }

    function getJudge (bytes32 id) external view returns (address) {
        return wagersMap[id].judge;
    }

    function getJudgesVote (bytes32 id) external view returns (uint) {
        return judgesVote[id];
    }

    function getLoser (bytes32 id) external view returns (address) {
        return wagersMap[id].loser;
    }


}