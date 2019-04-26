pragma solidity ^0.5.0;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract AuthorityGranter is Ownable {

    mapping (address => bool) internal isAuthorized;  

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

}