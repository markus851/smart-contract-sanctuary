pragma solidity 0.4.18;

// File: contracts/ERC20Interface.sol

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/KyberNetworkProxyInterface.sol

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}


contract Blarity {
  ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  ERC20 constant internal ACCEPT_DAI_ADDRESS = ERC20(0x00ad6d458402f60fd3bd25163575031acdce07538d);
  // ropsten: ERC20(0x00ad6d458402f60fd3bd25163575031acdce07538d);
  // mainnet: ERC20(0x0089d24a6b4ccb1b6faa2625fe562bdd9a23260359);
  // owner address
  address public owner;
  // campaign creator address
  struct CampaignCreator {
    address addr;
    // maximum amount to receive from smart contract
    uint amount;
    // is requested to get money from SC
    bool isRequested;
  }
  // start and end time
  uint public startTime;
  uint public endTime;
  // accepted token
  ERC20 public acceptedToken;
  uint public targetedMoney;
  bool public isReverted = false;

  struct Supplier {
    address addr;
    // maximum amount to receive from smart contract
    uint amount;
    // requested amount to get money from SC
    bool isRequested;
    bool isOwnerApproved;
    bool isCreatorApproved;
  }

  struct Donator {
    address addr;
    uint amount;
  }

  CampaignCreator campaignCreator;
  Supplier[] suppliers;
  Donator[] donators;

  // Withdraw funds
  event EtherWithdraw(uint amount, address sendTo);
  /**
   * @dev Withdraw Ethers
   */
  function withdrawEther(uint amount, address sendTo) public onlyOwner {
    sendTo.transfer(amount);
    EtherWithdraw(amount, sendTo);
  }

  event TokenWithdraw(ERC20 token, uint amount, address sendTo);
  /**
   * @dev Withdraw all ERC20 compatible tokens
   * @param token ERC20 The address of the token contract
   */
  function withdrawToken(ERC20 token, uint amount, address sendTo) public onlyOwner {
    require(token != acceptedToken);
    token.transfer(sendTo, amount);
    TokenWithdraw(token, amount, sendTo);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyCampaignCreator() {
    require(msg.sender == campaignCreator.addr);
    _;
  }

  // Transfer ownership
  event TransferOwner(address newOwner);
  function transferOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    TransferOwner(newOwner);
  }

  // Transfer camp creator
  event TransferCampaignCreator(address newCampCreator);
  function transferCampaignCreator(address newCampCreator) public onlyCampaignCreator {
    require(newCampCreator != address(0));
    campaignCreator = CampaignCreator({
      addr: newCampCreator,
      amount: campaignCreator.amount,
      isRequested: campaignCreator.isRequested
    });
    TransferOwner(newCampCreator);
  }

  function Blarity(
    address _campCreator,
    uint _campAmount,
    uint _endTime,
    uint _targetMoney,
    address[] supplierAddresses,
    uint[] supplierAmounts
  ) public {
    require(_campCreator != address(0));
    require(_targetMoney > 0);
    require(_endTime > now);
    require(supplierAddresses.length == supplierAmounts.length);
    owner = msg.sender;
    campaignCreator = CampaignCreator({addr: _campCreator, amount: _campAmount, isRequested: false});
    endTime = _endTime;
    acceptedToken = ACCEPT_DAI_ADDRESS;
    targetedMoney = _targetMoney;
    isReverted = false;
    for(uint i = 0; i < supplierAddresses.length; i++) {
      require(supplierAddresses[i] != address(0));
      require(supplierAmounts[i] > 0);
      Supplier memory sup = Supplier({
        addr: supplierAddresses[i],
        amount: supplierAmounts[i],
        isRequested: false,
        isOwnerApproved: false,
        isCreatorApproved: false
      });
      suppliers.push(sup);
    }
  }

  event AddNewSupplier(address _address, uint _amount);
  event ReplaceSupplier(address _address, uint _amount);
  // Add new supplier if not exist, replace current one if exit
  function addNewSupplier(address _address, uint _amount) public onlyOwner {
    require(now < endTime); // must not be ended
    require(_address != address(0));
    require(_amount > 0);
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _address) {
        if (suppliers[i].amount == _amount) { return; }
        suppliers[i].amount = _amount;
        suppliers[i].isRequested = false;
        suppliers[i].isCreatorApproved = false;
        suppliers[i].isOwnerApproved = false;
        ReplaceSupplier(_address, _amount);
        return;
      }
    }
    Supplier memory sup = Supplier({
      addr: _address,
      amount: _amount,
      isRequested: false,
      isCreatorApproved: false,
      isOwnerApproved: false
    });
    suppliers.push(sup);
    AddNewSupplier(_address, _amount);
  }

  event RemoveSupplier(address _address);
  function removeSupplier(address _address) public onlyOwner {
    require(now < endTime); // must not be ended
    require(_address != address(0));
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _address) {
        suppliers[i] = suppliers[suppliers.length - 1];
        // delete suppliers[suppliers.length - 1];
        suppliers.length--;
        RemoveSupplier(_address);
      }
    }
  }

  function updateTargetedMoney(uint _money) public onlyOwner {
    require(now < endTime); // must not be ended
    targetedMoney = _money;
  }

  function updateEndTime(uint _endTime) public onlyOwner {
    endTime = _endTime;
  }

  function updateIsReverted(bool _isReverted) public onlyOwner {
    isReverted = _isReverted;
  }

  event UpdateIsReverted(bool isReverted);
  function updateIsRevertedEndTimeReached() public onlyOwner {
    require(now >= endTime);
    require(isReverted == false);
    if (ACCEPT_DAI_ADDRESS.balanceOf(address(this)) < targetedMoney) {
      isReverted = true;
      UpdateIsReverted(true);
    }
  }

  event SupplierFundTransferRequested(address addr, uint amount);
  function requestTransferFundToSupplier() public {
    require(now >= endTime); // must be ended
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == msg.sender) {
        require(suppliers[i].amount > 0);
        require(suppliers[i].isRequested == false);
        require(ACCEPT_DAI_ADDRESS.balanceOf(address(this)) >= suppliers[i].amount);
        suppliers[i].isRequested = true;
        SupplierFundTransferRequested(msg.sender, suppliers[i].amount);
      }
    }
  }

  event ApproveSupplierFundTransferRequested(address addr, uint amount);
  event FundTransferredToSupplier(address supplier, uint amount);
  // Approve fund transfer to supplier from both campaign creator and owner
  function approveFundTransferToSupplier(address _supplier) public {
    require(now >= endTime); // must be ended
    require(msg.sender == owner || msg.sender == campaignCreator.addr);
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _supplier) {
        require(suppliers[i].amount > 0);
        require(ACCEPT_DAI_ADDRESS.balanceOf(address(this)) >= suppliers[i].amount);
        if (msg.sender == owner) {
          suppliers[i].isOwnerApproved = true;
        } else {
          suppliers[i].isCreatorApproved = true;
        }
        if (suppliers[i].isOwnerApproved && suppliers[i].isCreatorApproved) {
          // both approved, start transferring
          if (ACCEPT_DAI_ADDRESS.transferFrom(address(this), _supplier, suppliers[i].amount)) {
            suppliers[i].amount = 0;
            FundTransferredToSupplier(msg.sender, suppliers[i].amount);
          }
        } else {
          ApproveSupplierFundTransferRequested(msg.sender, suppliers[i].amount);
        }
      }
    }
  }

  event CreatorRequestFundTransfer(address _address, uint _amount);
  function creatorRequestFundTransfer() public onlyCampaignCreator {
    require(now >= endTime); // must be ended
    require(campaignCreator.amount > 0);
    campaignCreator.isRequested = true;
    CreatorRequestFundTransfer(msg.sender, campaignCreator.amount);
  }

  event FundTransferToCreator(address _from, address _to, uint _amount);
  function approveAndTransferFundToCreator() public onlyOwner {
    require(now >= endTime); // must be ended
    require(campaignCreator.amount > 0);
    require(campaignCreator.isRequested);
    if (ACCEPT_DAI_ADDRESS.transferFrom(address(this), campaignCreator.addr, campaignCreator.amount)) {
      campaignCreator.amount = 0;
      FundTransferToCreator(msg.sender, campaignCreator.addr, campaignCreator.amount);
    }
  }
  event Donated(address _address, uint _amount);
  function donateDAI(uint amount) public {
    require(amount > 0);
    require(now < endTime);
    require(ACCEPT_DAI_ADDRESS.balanceOf(msg.sender) >= amount);
    if (ACCEPT_DAI_ADDRESS.transferFrom(msg.sender, address(this), amount)) {
      for(uint i = 0; i < donators.length; i++) {
        if (donators[i].addr == msg.sender) {
          donators[i].amount += amount;
          Donated(msg.sender, amount);
          return;
        }
      }
      donators.push(Donator({addr: msg.sender, amount: amount}));
      Donated(msg.sender, amount);
    }
  }

  function approveToken(KyberNetworkProxyInterface network, ERC20 token, uint amount) public {
      if (token.allowance(address(this), network) >= amount) { return; }
      token.approve(network, amount);
  }
 
  function donateToken(KyberNetworkProxyInterface network, ERC20 src, uint srcAmount, uint maxDestAmount, uint minConversionRate, address walletId) public payable {
    if (src != ETH_TOKEN_ADDRESS) {
       require(src.transferFrom(msg.sender, address(this), srcAmount));
    } else {
        require(address(this).send(msg.value));
    }
    bytes memory hint;
    uint amount = network.tradeWithHint.value(msg.value)(src, srcAmount, ACCEPT_DAI_ADDRESS, address(this), maxDestAmount, minConversionRate, walletId, hint);
    for(uint i = 0; i < donators.length; i++) {
      if (donators[i].addr == msg.sender) {
        donators[i].amount += amount;
        Donated(msg.sender, amount);
        return;
      }
    }
    donators.push(Donator({addr: msg.sender, amount: amount}));
    Donated(msg.sender, amount);
  }

  event Refunded(address _address, uint _amount);
  function requestRefundDonator() public {
    require(isReverted == true); // only refund if it is reverted
    for(uint i = 0; i < donators.length; i++) {
      if (donators[i].addr == msg.sender) {
        require(donators[i].amount > 0);
        uint amount = donators[i].amount;
        if (ACCEPT_DAI_ADDRESS.transfer(msg.sender, amount)) {
          donators[i].amount = 0;
          Refunded(msg.sender, amount);
          return;
        }
      }
    }
  }

  function getCampaignCreator() public view returns (address _address, uint _amount) {
    return (campaignCreator.addr, campaignCreator.amount);
  }

  function getNumberSuppliers() public view returns (uint numberSuppliers) {
    numberSuppliers = suppliers.length;
    return numberSuppliers;
  }

  function getSuppliers()
  public view returns (address[] memory addresses, uint[] memory amounts, bool[] isRequested, bool[] isOwnerApproved, bool[] isCreatorApproved) {
    addresses = new address[](suppliers.length);
    amounts = new uint[](suppliers.length);
    isRequested = new bool[](suppliers.length);
    isOwnerApproved = new bool[](suppliers.length);
    isCreatorApproved = new bool[](suppliers.length);
    for(uint i = 0; i < suppliers.length; i++) {
      addresses[i] = suppliers[i].addr;
      amounts[i] = suppliers[i].amount;
      isRequested[i] = suppliers[i].isRequested;
      isOwnerApproved[i] = suppliers[i].isOwnerApproved;
      isCreatorApproved[i] = suppliers[i].isCreatorApproved;
    }
    return (addresses, amounts, isRequested, isOwnerApproved, isCreatorApproved);
  }

  function getSupplier(address _addr)
  public view returns (address _address, uint amount, bool isRequested, bool isOwnerApproved, bool isCreatorApproved) {
    for(uint i = 0; i < suppliers.length; i++) {
      if (suppliers[i].addr == _addr) {
        return (_addr, suppliers[i].amount, suppliers[i].isRequested, suppliers[i].isOwnerApproved, suppliers[i].isCreatorApproved);
      }
    }
  }

  function getNumberDonators() public view returns (uint numberDonators) {
    numberDonators = donators.length;
    return numberDonators;
  }

  function getDonators() public view returns (address[] addresses, uint[] amounts) {
    addresses = new address[](donators.length);
    amounts = new uint[](donators.length);
    for(uint i = 0; i < donators.length; i++) {
      addresses[i] = donators[i].addr;
      amounts[i] = donators[i].amount;
    }
    return (addresses, amounts);
  }

  function getDonator(address _addr) public view returns (address _address, uint _amount) {
    for(uint i = 0; i < donators.length; i++) {
      if (donators[i].addr == _addr) {
        return (_addr, donators[i].amount);
      }
    }
  }

  function getDAIBalance() public view returns (uint balance) {
    return ACCEPT_DAI_ADDRESS.balanceOf(address(this));
  }
}