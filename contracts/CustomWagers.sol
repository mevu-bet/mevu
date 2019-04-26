pragma solidity ^0.5.0;
import "./AuthorityGranter.sol";
contract CustomWagers is AuthorityGranter {
        
    struct Wager {
        uint endTime;
        uint reportingEndTime;            
        uint origValue;
        uint winningValue;        
        uint makerChoice;
        uint takerChoice;
        uint odds;
        uint makerWinnerVote;
        uint takerWinnerVote;
        address payable maker;
        address payable taker;
        address payable judge;        
        address payable winner;         
        bool makerCancelRequest;
        bool takerCancelRequest;       
        bool settled;        
    }

    mapping (bytes32 => bool) private cancelled;   
    mapping (bytes32 => Wager) private wagersMap;
    mapping (address => mapping (bytes32 => bool)) private recdRefund;
    mapping  (bytes32 => uint) private judgesVote;

    
    function makeWager (
        bytes32 wagerId,
        uint endTime,
        uint reportingEndTime,          
        uint origValue,
        uint winningValue,        
        uint makerChoice,
        uint takerChoice,
        uint odds,
        uint makerWinnerVote,
        uint takerWinnerVote,
        address payable maker
        
        )
            external
            onlyAuth             
        {
        Wager memory thisWager = Wager (endTime,
                                        reportingEndTime,
                                        origValue,
                                        winningValue,
                                        makerChoice,
                                        takerChoice,
                                        odds,
                                        makerWinnerVote,
                                        takerWinnerVote,
                                        maker,
                                        address(0),
                                        address(0),
                                        address(0),                                       
                                        false,
                                        false,                                        
                                        false);
        wagersMap[wagerId] = thisWager;       
    }

    function addJudge (bytes32 wagerId, address payable judge) external onlyAuth {
        wagersMap[wagerId].judge = judge;
    }

    function setCancelled (bytes32 wagerId) external onlyAuth {
        cancelled[wagerId] = true;
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

    function setTaker (bytes32 wagerId, address payable taker) external onlyAuth {
        wagersMap[wagerId].taker = taker;
    }

    function setWinner (bytes32 id, address payable winner) external onlyAuth {
        wagersMap[id].winner = winner;        
    }

    function setJudgesVote (bytes32 id, uint vote) external onlyAuth {
        judgesVote[id] = vote;
    }

    // function setLoser (bytes32 id, address loser) external onlyAuth {
    //     wagersMap[id].loser = loser;
    // }

    function setWinningValue (bytes32 wagerId, uint value) external onlyAuth {
        wagersMap[wagerId].winningValue = value;
    }

    function getCancelled (bytes32 wagerId) external view returns (bool) {
        return cancelled[wagerId];
    }

    function getEndTime (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].endTime;
    } 

    function getReportingEndTime (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].reportingEndTime;
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

    function getMaker(bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].maker;
    }

    function getTaker(bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].taker;
    }

    function getMakerChoice (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].makerChoice;
    }

    function getTakerChoice (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].takerChoice;
    }

    function getMakerCancelRequest (bytes32 wagerId) external view returns (bool) {
        return wagersMap[wagerId].makerCancelRequest;
    }

    function getTakerCancelRequest (bytes32 wagerId) external view returns (bool) {
        return wagersMap[wagerId].takerCancelRequest;
    }

    function getMakerWinVote (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].makerWinnerVote;
    }
    
    function getTakerWinVote (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].takerWinnerVote;
    }

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) {
        return recdRefund[bettor][wagerId];
    }    

    function getOdds (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].odds;
    }

    function getOrigValue (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].origValue;
    }

    function getWinningValue (bytes32 wagerId) external view returns (uint) {
        return wagersMap[wagerId].winningValue;
    }

    function getWinner (bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].winner;
    } 
    
    function getLoser (bytes32 wagerId) external view returns (address payable) {
        address payable winner = wagersMap[wagerId].winner;
        address payable maker = wagersMap[wagerId].maker;
        address payable taker = wagersMap[wagerId].taker;
        if (winner == taker) {
            return maker;
        } else if  (winner == maker) {
            return taker;
        } else {
            return address(0);
        }
    }

    function getJudge (bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].judge;
    }

    function getJudgesVote (bytes32 wagerId) external view returns (uint) {
        return judgesVote[wagerId];
    }

   


}