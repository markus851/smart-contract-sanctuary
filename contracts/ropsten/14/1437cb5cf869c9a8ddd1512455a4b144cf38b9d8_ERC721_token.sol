pragma solidity ^0.4.25;

contract ERC721_interface{

     event Transfer(address indexed _to, uint256 indexed _tokenId);
     event NewEgg(uint eggId, string name, uint dna);

     function balanceOf(address _owner) external view returns (uint256);
     function ownerOf(uint256 _tokenId) external view returns (address);
     function transfer(address _to, uint256 _tokenId) external payable;
 }
 
 contract Owned {
    address public owner; 
 }

contract ERC721_token is ERC721_interface, Owned {
    mapping(address => uint) eggBalances;
    mapping(uint => address) public eggToOwner;
    mapping(uint => address) eggApprovals;
    
  function create(string _name) public {
    //創建動物轉蛋的function，要給他一個DNA
    uint id = now;
    uint dna = uint(keccak256(_name));
    eggToOwner[id] = msg.sender;
    eggBalances[msg.sender]++;
    emit NewEgg(id, _name, dna);
  }

  //ERC721_interface function都要實作
  function balanceOf(address _owner) external view returns (uint256) {
      return eggBalances[_owner];
  }
  
  //_tokenId持有者
  function ownerOf(uint256 _tokenId) external view returns (address) {
      return eggToOwner[_tokenId];
  }
  
  function approve(address _approved, uint256 _tokenId) external payable {
    eggApprovals[_tokenId] = _approved;
  }
  
  //交易
  function transfer(address _to, uint256 _tokenId) external payable {
      require(eggToOwner[_tokenId] == msg.sender || eggApprovals[_tokenId] == msg.sender);
      _transfer(_to, _tokenId);
  }
  
  function _transfer(address _to, uint256 _tokenId) private {
      eggBalances[_to]++;
      eggBalances[msg.sender]--;
      eggToOwner[_tokenId] = _to;
      emit Transfer(_to, _tokenId);
  }

}