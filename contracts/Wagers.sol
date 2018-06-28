pragma solidity ^0.4.18;
//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";
contract Wagers is AuthorityGranter {
        
    struct Wager {
        bytes32 eventId;        
        uint origValue;
        uint winningValue;        
        uint makerChoice;
      
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
        bool takerVoted;       
        bool makerVoted;
    }
 
    mapping (bytes32 => Wager) wagersMap;
    mapping (address => mapping (bytes32 => bool)) recdRefund;  
    
    function makeWager (
        bytes32 wagerId, 
        bytes32 eventId,        
        uint origValue,
        uint winningValue,        
        uint makerChoice,
       
        uint odds,
        uint makerWinnerVote,
        uint takerWinnerVote,
        address maker
        )
            external
            onlyAuth             
        {
        Wager memory thisWager = Wager (eventId,
                                        origValue,
                                        winningValue,
                                        makerChoice,
                                      
                                        odds,
                                        makerWinnerVote,
                                        takerWinnerVote,
                                        maker,
                                        address(0),
                                        address(0),
                                        address(0),
                                        false,
                                        false,
                                        false,
                                        false,
                                        false,
                                        false);
        wagersMap[wagerId] = thisWager;       
    }    

    function setLocked (bytes32 wagerId) external onlyAuth { wagersMap[wagerId].locked = true; }

    function setSettled (bytes32 wagerId) external onlyAuth { wagersMap[wagerId].settled = true; }

    function setMakerWinVote (bytes32 id, uint winnerVote) external onlyAuth { 
        wagersMap[id].makerWinnerVote = winnerVote;
        wagersMap[id].makerVoted = true; 
    }

    function setTakerWinVote (bytes32 id, uint winnerVote) external onlyAuth { 
        wagersMap[id].takerWinnerVote = winnerVote;
        wagersMap[id].takerVoted = true;
    }

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth { recdRefund[bettor][wagerId] = true; }

    function setMakerCancelRequest (bytes32 id) external onlyAuth { wagersMap[id].makerCancelRequest = true; }

    function setTakerCancelRequest (bytes32 id) external onlyAuth { wagersMap[id].takerCancelRequest = true; }

    function setTaker (bytes32 wagerId, address taker) external onlyAuth { wagersMap[wagerId].taker = taker; }

    function setWinner (bytes32 id, address winner) external onlyAuth { wagersMap[id].winner = winner; }

    function setLoser (bytes32 id, address loser) external onlyAuth { wagersMap[id].loser = loser; }

    function setWinningValue (bytes32 wagerId, uint value) external onlyAuth { wagersMap[wagerId].winningValue = value; }

    function getEventId(bytes32 wagerId) external view returns (bytes32) { return wagersMap[wagerId].eventId; }

    function getLocked (bytes32 id) external view returns (bool) { return wagersMap[id].locked; }

    function getSettled (bytes32 id) external view returns (bool) { return wagersMap[id].settled; }

    function getMaker(bytes32 id) external view returns (address) { return wagersMap[id].maker; }

    function getTaker(bytes32 id) external view returns (address) { return wagersMap[id].taker; }

    function getMakerChoice (bytes32 id) external view returns (uint) { return wagersMap[id].makerChoice; }

    // function getTakerChoice (bytes32 id) external view returns (uint) { return wagersMap[id].takerChoice; }

    function getMakerCancelRequest (bytes32 id) external view returns (bool) { return wagersMap[id].makerCancelRequest; }

    function getTakerCancelRequest (bytes32 id) external view returns (bool) { return wagersMap[id].takerCancelRequest; }

    function getMakerWinVote (bytes32 id) external view returns (uint) { return wagersMap[id].makerWinnerVote; }

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) { return recdRefund[bettor][wagerId]; }

    function getTakerWinVote (bytes32 id) external view returns (uint) { return wagersMap[id].takerWinnerVote; }

    function getOdds (bytes32 id) external view returns (uint) { return wagersMap[id].odds; }

    function getOrigValue (bytes32 id) external view returns (uint) { return wagersMap[id].origValue; }

    function getWinningValue (bytes32 id) external view returns (uint) { return wagersMap[id].winningValue; }

    function getWinner (bytes32 id) external view returns (address) { return wagersMap[id].winner; }

    function getLoser (bytes32 id) external view returns (address) { return wagersMap[id].loser; }
    
    function getMakerWinVoted (bytes32 id) external view returns (bool) { return wagersMap[id].makerVoted; }

    function getTakerWinVoted (bytes32 id) external view returns (bool) { return wagersMap[id].takerVoted; }
}