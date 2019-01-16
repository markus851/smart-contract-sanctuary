pragma solidity ^0.4.18;

interface trinityData{
    
    function getChannelBalance(bytes32 channelId) external view returns (uint256);
    function getChannelStatus(bytes32 channelId) external view returns(uint8);
    function getChannelExist(bytes32 channelId) external view returns(bool);
    function getChannelClosingSettler(bytes32 channelId) external view returns (address);
    function getSettlingTimeoutBlock(bytes32 channelId) external view returns(uint256);
    
    function getChannelPartners(bytes32 channelId) external view returns (address,address);
    function getClosingSettle(bytes32 channelId)external view returns (uint256,uint256,address,address,uint256,uint256);
    function getTimeLock(bytes32 channelId, bytes32 lockHash) external view returns(address,address,uint256,uint256, bool);
    function getHtlcPaymentBlock(bytes32 channelId, bytes32 lockHash) external view returns(uint256);
}

contract TrinityEvent{

    event Deposit(bytes32 channleId, address partnerA, uint256 amountA,address partnerB, uint256 amountB);
    event UpdateDeposit(bytes32 channleId, address partnerA, uint256 amountA, address partnerB, uint256 amountB);    
    event QuickCloseChannel(bytes32 channleId, address closer, uint256 amount1, address partner, uint256 amount2);
    event WithdrawBalance(bytes32 channleId, address closer, uint256 amount1, address partner, uint256 amount2);
    event CloseChannel(bytes32 channleId, address invoker, uint256 nonce, uint256 blockNumber);
    event UpdateTransaction(bytes32 channleId, address partnerA, uint256 amountA, address partnerB, uint256 amountB);
    event Settle(bytes32 channleId, address partnerA, uint256 amountA, address partnerB, uint256 amountB);
    event Withdraw(bytes32 channleId, address invoker, bytes32 hashLock, bytes32 secret, uint256 paymentBlock);
    event WithdrawUpdate(bytes32 channleId, address invoker);
    event WithdrawSettle(bytes32 channleId, address invoker, bytes32 hashLock, uint256 lockAmount);
}

contract Owner{
    address public owner;
    bool paused;
    
    constructor() public{
        owner = msg.sender;
        paused = false;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    } 
    
    modifier whenNotPaused(){
        require(!paused);
        _;
    }

    modifier whenPaused(){
        require(paused);
        _;
    }

    //disable contract setting funciton
    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    //enable contract setting funciton
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }    
}

contract VerifyTrinitySignature{
    
    function verifyTimelock(bytes32 channelId,
                            address sender,
                            address receiver,
                            uint256 lockPeriod ,
                            uint256 lockAmount,
                            bytes32 lockHash,
                            bytes partnerAsignature,
                            bytes partnerBsignature) internal pure returns(bool)  {

        address recoverA = verifyLockSignature(channelId, sender, receiver, lockPeriod, lockAmount,lockHash, partnerAsignature);
        address recoverB = verifyLockSignature(channelId, sender, receiver, lockPeriod, lockAmount,lockHash, partnerBsignature);
        if ((recoverA == sender && recoverB == receiver) || (recoverA == receiver && recoverB == sender)){
            return true;
        }
        return false;
    }

    function verifyLockSignature(bytes32 channelId,
                                address sender,
                                address receiver,
                                uint256 lockPeriod ,
                                uint256 lockAmount,
                                bytes32 lockHash,
                                bytes signature) internal pure returns(address)  {

        bytes32 data_hash;
        address recover_addr;
        //data_hash=keccak256(channelId, sender, receiver, lockPeriod, lockAmount,lockHash);
        data_hash = keccak256(abi.encodePacked(channelId, sender, receiver, lockPeriod, lockAmount,lockHash));        
        recover_addr=_recoverAddressFromSignature(signature,data_hash);
        return recover_addr;
        

        
    }
    
     /*
     * Funcion:   parse both signature for check whether the transaction is valid
     * Parameters:
     *    addressA: node address that deployed on same channel;
     *    addressB: node address that deployed on same channel;
     *    balanceA : nodaA assets amount;
     *    balanceB : nodaB assets assets amount;
     *    nonce: transaction nonce;
     *    signatureA: A signature for this transaction;
     *    signatureB: B signature for this transaction;
     * Return:
     *    result: if both signature is valid, return TRUE, or return False.
    */    
    
    function verifyTransaction(
        bytes32 channelId,
        uint256 nonce,
        address addressA,
        uint256 balanceA,
        address addressB,
        uint256 balanceB,
        bytes32 lockHash,
        bytes32 secret,
        bytes signatureA,
        bytes signatureB) internal pure returns(bool result){

        address recoverA;
        address recoverB;

        recoverA = recoverAddressFromSignature(channelId, nonce, addressA, balanceA, addressB, balanceB, lockHash, secret, signatureA);
        recoverB = recoverAddressFromSignature(channelId, nonce, addressA, balanceA, addressB, balanceB, lockHash, secret, signatureB);
        if ((recoverA == addressA && recoverB == addressB) || (recoverA == addressB && recoverB == addressA)){
            return true;
        }
        return false;
    }   
    
    function recoverAddressFromSignature(
        bytes32 channelId,
        uint256 nonce,
        address addressA,
        uint256 balanceA,
        address addressB,
        uint256 balanceB,
        bytes32 lockHash,
        bytes32 secret,        
        bytes signature
        ) internal pure returns(address)  {

        bytes32 data_hash;
        address recover_addr;
        data_hash=keccak256(abi.encodePacked(channelId, nonce, addressA, balanceA, addressB, balanceB, lockHash, secret));
        
        recover_addr=_recoverAddressFromSignature(signature,data_hash);
        return recover_addr;
    }    

    function verifyCommonTransaction(
        bytes32 channelId,
        uint256 nonce,
        address addressA,
        uint256 balanceA,
        address addressB,
        uint256 balanceB,
        bytes signatureA,
        bytes signatureB) internal pure returns(bool result){

        address recoverA;
        address recoverB;

        recoverA = recoverAddressFromCommonSignature(channelId, nonce, addressA, balanceA, addressB, balanceB, signatureA);
        recoverB = recoverAddressFromCommonSignature(channelId, nonce, addressA, balanceA, addressB, balanceB, signatureB);
        if ((recoverA == addressA && recoverB == addressB) || (recoverA == addressB && recoverB == addressA)){
            return true;
        }
        return false;
    }

    function recoverAddressFromCommonSignature(
        bytes32 channelId,
        uint256 nonce,
        address addressA,
        uint256 balanceA,
        address addressB,
        uint256 balanceB,
        bytes signature
        ) internal pure returns(address)  {

        bytes32 data_hash;
        address recover_addr;
        data_hash=keccak256(abi.encodePacked(channelId, nonce, addressA, balanceA, addressB, balanceB));
        recover_addr=_recoverAddressFromSignature(signature,data_hash);
        return recover_addr;
    }

	function _recoverAddressFromSignature(bytes signature,bytes32 dataHash) internal pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r,s,v)=signatureSplit(signature);

        return ecrecoverDecode(dataHash,v, r, s);
    }

    function signatureSplit(bytes signature)
        pure
        internal
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 0xff)
        }
        v=v+27;
        require((v == 27 || v == 28), "check v value");
    }

    function ecrecoverDecode(bytes32 datahash,uint8 v,bytes32 r,bytes32 s) internal pure returns(address addr){

        addr=ecrecover(datahash,v,r,s);
        return addr;
    }
}

library SafeMath{
    
    function add256(uint256 addend, uint256 augend) internal pure returns(uint256 result){
        uint256 sum = addend + augend;
        assert(sum >= addend);
        return sum;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract TrinityContractCore is Owner, VerifyTrinitySignature, TrinityEvent{

    using SafeMath for uint256;

    uint8 constant OPENING = 1;
    uint8 constant CLOSING = 2;
    uint8 constant LOCKING = 3;
    
    trinityData public trinityDataContract;
    
    constructor(address _dataAddress) public{
        trinityDataContract = trinityData(_dataAddress);
    }
    
    function getChannelBalance(bytes32 channelId) public view returns (uint256){
        return trinityDataContract.getChannelBalance(channelId);
    }   

   function getChannelStatus(bytes32 channelId) public view returns (uint8){
        return trinityDataContract.getChannelStatus(channelId);
    }

    function getTimeoutBlock(bytes32 channelId) public view returns (uint256){
        return trinityDataContract.getSettlingTimeoutBlock(channelId);
    }
    
    function getHtlcTimeoutBlock(bytes32 channelId, bytes32 lockHash) public view returns (uint256){
        return trinityDataContract.getHtlcPaymentBlock(channelId, lockHash);
    }    

    function setDataContract(address _dataContract) external onlyOwner {
        trinityDataContract = trinityData(_dataContract);
    }

    /*
      * Function: 1. Lock both participants assets to the contract
      *           2. setup channel.
      *           Before lock assets,both participants must approve contract can spend special amout assets.
      * Parameters:
      *    partnerA: partner that deployed on same channel;
      *    partnerB: partner that deployed on same channel;
      *    amountA : partnerA will lock assets amount;
      *    amountB : partnerB will lock assets amount;
      *    signedStringA: partnerA signature for this transaction;
      *    signedStringB: partnerB signature for this transaction;
      * Return:
      *    Null;
    */
    
    function deposit(bytes32 channelId,
                     uint256 nonce,
                     address funderAddress,
                     uint256 funderAmount,
                     address partnerAddress,
                     uint256 partnerAmount,                    
                     bytes funderSignature,
                     bytes partnerSignature) external whenNotPaused{

        //verify both signature to check the behavious is valid.
        
        require(verifyCommonTransaction(channelId, 
                                        nonce, 
                                        funderAddress, 
                                        funderAmount, 
                                        partnerAddress, 
                                        partnerAmount,
                                        funderSignature, 
                                        partnerSignature) == true);
        
        bool channelExist = trinityDataContract.getChannelExist(channelId);
        //if channel have existed, can not create it again
        require(channelExist == false, "the channel should not exist");
        
        bool callResult = address(trinityDataContract).call(bytes4(keccak256("depositData(bytes32,address,uint256,address,uint256)")),
                                                channelId,
                                                funderAddress,
                                                funderAmount,
                                                partnerAddress,
                                                partnerAmount);
                                                
        require(callResult == true, "call should success");
        
        emit Deposit(channelId, funderAddress, funderAmount, partnerAddress, partnerAmount);
    }

    function updateDeposit(bytes32 channelId,
                           uint256 nonce,
                           address funderAddress,
                           uint256 funderAmount,
                           address partnerAddress,
                           uint256 partnerAmount,                        
                           bytes funderSignature,
                           bytes partnerSignature) external whenNotPaused{
        
        //verify both signature to check the behavious is valid.
        require(verifyCommonTransaction(channelId, 
                                        nonce, 
                                        funderAddress, 
                                        funderAmount, 
                                        partnerAddress, 
                                        partnerAmount,                           
                                        funderSignature, 
                                        partnerSignature) == true, "verify signature");
        
        require(getChannelStatus(channelId) == OPENING, "channel status should be opening");

        bool callResult = address(trinityDataContract).call(bytes4(keccak256("updateDeposit(bytes32,address,uint256,address,uint256)")),
                                                channelId,
                                                funderAddress,
                                                funderAmount,
                                                partnerAddress,
                                                partnerAmount);

        require(callResult == true, "call should be success");
        
        emit UpdateDeposit(channelId, funderAddress, funderAmount, partnerAddress, partnerAmount);
    }
    
    function withdrawBalance(bytes32 channelId,
                               uint256 nonce,
                               address funder,
                               uint256 funderBalance,
                               address partner,
                               uint256 partnerBalance,
                               bytes closerSignature,
                               bytes partnerSignature) external whenNotPaused{

        uint256 totalBalance = 0;
        bool  mutex = false;

        //verify both signatures to check the behavious is valid
        require(verifyCommonTransaction(channelId, 
                                        nonce, 
                                        funder, 
                                        funderBalance, 
                                        partner, 
                                        partnerBalance,
                                        closerSignature, 
                                        partnerSignature) == true, "verify signature");

        require(nonce == 0, "nonce should equal zero");

        require((msg.sender == funder || msg.sender == partner), "caller should be channel partner");

        //channel should be opening
        require(getChannelStatus(channelId) == OPENING, "channel status must be opening");
        
        //sum of both balance should not larger than total deposited assets
        require(mutex == false);
        mutex = true;
        
        totalBalance = funderBalance.add256(partnerBalance);
        require(totalBalance <= getChannelBalance(channelId),"settle balance should not be greater than  channle total balance");
        
        bool callResult = address(trinityDataContract).call(bytes4(keccak256("withdrawBalance(bytes32,address,uint256,address,uint256)")),
                                                channelId,
                                                funder,
                                                funderBalance,
                                                partner,
                                                partnerBalance);

        require(callResult == true, "call result");
        
        mutex = false;        
        
        emit WithdrawBalance(channelId, funder, funderBalance, partner, partnerBalance);
    }    

    function quickCloseChannel(bytes32 channelId,
                               uint256 nonce,
                               address funder,
                               uint256 funderBalance,
                               address partner,
                               uint256 partnerBalance,
                               bytes closerSignature,
                               bytes partnerSignature) external whenNotPaused{

        uint256 depositTotalBalance = 0;
        uint256 closeTotalBalance = 0;
        bool  mutex = false;
 
        //verify both signatures to check the behavious is valid
        require(verifyCommonTransaction(channelId, 
                                        nonce, 
                                        funder, 
                                        funderBalance, 
                                        partner, 
                                        partnerBalance,
                                        closerSignature, 
                                        partnerSignature) == true, "verify signature");

        require(nonce == 0, "nonce should equal zero");

        require((msg.sender == funder || msg.sender == partner), "verify caller");

        //channel should be opening
        require(getChannelStatus(channelId) == OPENING, "check channel status");
        
        require(mutex == false);
        mutex = true;          
        
        //sum of both balance should not larger than total deposited assets
        depositTotalBalance = getChannelBalance(channelId);
        closeTotalBalance = funderBalance.add256(partnerBalance);
        require(closeTotalBalance <= depositTotalBalance,"check channel balance");
        
        handleQuickCloseChannel(msg.sender,channelId, funder, funderBalance, partner, partnerBalance, depositTotalBalance);
        
        mutex = false;
        emit QuickCloseChannel(channelId, funder, funderBalance, partner, partnerBalance); 
    }

    function handleQuickCloseChannel(address invoker,
                                bytes32 channelId,
                                address funder,
                                uint256 funderBalance,
                                address partner,
                                uint256 partnerBalance,
                                uint256 depositTotalBalance) internal{
        uint256 peerBalance = 0;
        bool callResult = false;
        
        if (invoker == funder){
            
            peerBalance = depositTotalBalance.sub256(funderBalance);
            callResult = address(trinityDataContract).call(bytes4(keccak256("quickCloseChannel(bytes32,address,uint256,address,uint256)")),
                                            channelId,
                                            funder,
                                            funderBalance,
                                            partner,
                                            peerBalance);            
        }
        else{
            peerBalance = depositTotalBalance.sub256(partnerBalance);
            callResult = address(trinityDataContract).call(bytes4(keccak256("quickCloseChannel(bytes32,address,uint256,address,uint256)")),
                                            channelId,
                                            funder,
                                            peerBalance,
                                            partner,
                                            partnerBalance);              
        }
        
        require(callResult == true, "call result");
    }

    /*
     * Funcion:   1. set channel status as closing
                  2. withdraw assets for partner against closer
                  3. freeze closer settle assets untill setelement timeout or partner confirmed the transaction;
     * Parameters:
     *    partnerA: partner that deployed on same channel;
     *    partnerB: partner that deployed on same channel;
     *    settleBalanceA : partnerA will withdraw assets amount;
     *    settleBalanceB : partnerB will withdraw assets amount;
     *    signedStringA: partnerA signature for this transaction;
     *    signedStringB: partnerB signature for this transaction;
     *    settleNonce: closer provided nonce for settlement;
     * Return:
     *    Null;
     */

    function closeChannel(bytes32 channelId,
                          uint256 nonce,
                          address founder,
                          uint256 founderBalance,      
                          address partner,
                          uint256 partnerBalance,
                          bytes32 lockHash,
                          bytes32 secret,
                          bytes closerSignature,
                          bytes partnerSignature) public whenNotPaused{

        require(nonce != 0, "check nonce");

        require((msg.sender == founder || msg.sender == partner), "check caller");

        //verify both signatures to check the behavious is valid
        if(nonce != 1){
            require(verifyTransaction(channelId, 
                                    nonce, 
                                    founder, 
                                    founderBalance, 
                                    partner, 
                                    partnerBalance,
                                    lockHash,
                                    secret,
                                    closerSignature, 
                                    partnerSignature) == true, "verify signature");            
        }
        else{
            require(verifyCommonTransaction(channelId, 
                                            nonce, 
                                            founder, 
                                            founderBalance, 
                                            partner, 
                                            partnerBalance,
                                            closerSignature, 
                                            partnerSignature) == true);     
        }

        handleCloseChannel(msg.sender,
                            channelId, 
                            nonce,
                            founder,
                            founderBalance, 
                            partner,
                            partnerBalance);
    }

    function handleCloseChannel(address invoker,
                                bytes32 channelId,
                                uint256 nonce,
                                address founder,
                                uint256 founderBalance,      
                                address partner,
                                uint256 partnerBalance) internal{
        
        uint256 closeTotalBalance = 0;
        uint256 depositTotalBalance = 0;
        uint256 remaingBalance = 0;
        bool  mutex = false;
        
        require(mutex == false);
        mutex = true;         
        
        //channel should be opening
        require(getChannelStatus(channelId) == OPENING, "check channel status");

        //sum of both balance should not larger than total deposited assets
        closeTotalBalance = founderBalance.add256(partnerBalance);
        depositTotalBalance = getChannelBalance(channelId);
        require(closeTotalBalance <= depositTotalBalance, "check total balance"); 
        
        if (invoker == founder){
            //sender want close channel actively, withdraw partner balance firstly
            remaingBalance = depositTotalBalance.sub256(founderBalance);
            require(address(trinityDataContract).call(bytes4(keccak256("closeChannel(bytes32,uint256,address,uint256,address,uint256)")),
                                                channelId,
                                                nonce,
                                                founder,
                                                founderBalance,
                                                partner,
                                                remaingBalance) == true, "call restul");
        }
        else if(invoker == partner)
        {
            remaingBalance = depositTotalBalance.sub256(partnerBalance);
            require(address(trinityDataContract).call(bytes4(keccak256("closeChannel(bytes32,uint256,address,uint256,address,uint256)")),
                                                channelId,
                                                nonce,
                                                partner,
                                                partnerBalance,
                                                founder,
                                                remaingBalance) == true, "call result");
        }
        
        mutex = false;
        
        emit CloseChannel(channelId, msg.sender, nonce, getTimeoutBlock(channelId));        
        
    }

    /*
     * Funcion: After closer apply closed channle, partner update owner final transaction to check whether closer submitted invalid information
     *      1. if bothe nonce is same, the submitted settlement is valid, withdraw closer assets
            2. if partner nonce is larger than closer, then jugement closer have submitted invalid data, withdraw closer assets to partner;
            3. if partner nonce is less than closer, then jugement closer submitted data is valid, withdraw close assets.
     * Parameters:
     *    partnerA: partner that deployed on same channel;
     *    partnerB: partner that deployed on same channel;
     *    updateBalanceA : partnerA will withdraw assets amount;
     *    updateBalanceB : partnerB will withdraw assets amount;
     *    signedStringA: partnerA signature for this transaction;
     *    signedStringB: partnerB signature for this transaction;
     *    settleNonce: closer provided nonce for settlement;
     * Return:
     *    Null;
    */
    function updateTransaction(bytes32 channelId,
                               uint256 nonce,
                               address partnerA,
                               uint256 updateBalanceA,       
                               address partnerB,
                               uint256 updateBalanceB,
                               bytes32 lockHash,
                               bytes32 secret,
                               bytes signedStringA,
                               bytes signedStringB) external whenNotPaused{

        uint256 updateTotalBalance = 0;
        
        require(verifyTransaction(channelId,
                                  nonce, 
                                  partnerA, 
                                  updateBalanceA, 
                                  partnerB, 
                                  updateBalanceB, 
                                  lockHash, 
                                  secret, 
                                  signedStringA, 
                                  signedStringB) == true, "verify signature");

        require(nonce != 0, "check nonce");

        if (lockHash == keccak256(abi.encodePacked(secret))){
            // update HTLC transaction
            
            handleHTLCUpdateTx(msg.sender, channelId, lockHash);
        }
        else{
            // update RMSC transaction
            
            // only when channel status is closing, node can call it
            require(getChannelStatus(channelId) == CLOSING, "check channel status");

            // channel closer can not call it
            require(msg.sender == trinityDataContract.getChannelClosingSettler(channelId), "check settler");

            //sum of both balance should not larger than total deposited asset
            updateTotalBalance = updateBalanceA.add256(updateBalanceB);
            require(updateTotalBalance <= getChannelBalance(channelId), "check total balance");
    
            handleRSMCUpdateTx(msg.sender, channelId, nonce, partnerA, updateBalanceA, partnerB, updateBalanceB);              
            
        }
    }    
    
    function handleRSMCUpdateTx(address invoker,
                                bytes32 channelId,
                                uint256 nonce,
                                address partnerA,
                                uint256 updateBalanceA,
                                address partnerB,
                                uint256 updateBalanceB) internal{
        
        address channelSettler;
        address channelCloser;
        uint256 closingNonce;
        uint256 closerBalance;
        uint256 settlerBalance;
        
        (closingNonce, ,channelCloser,channelSettler,closerBalance,settlerBalance) = trinityDataContract.getClosingSettle(channelId);
        // if updated nonce is less than (or equal to) closer provided nonce, folow closer provided balance allocation
        
  
        // if updated nonce is equal to nonce+1 that closer provided nonce, folow partner provided balance allocation
        if ((nonce == closingNonce) || (nonce == (closingNonce + 1))){
            if (invoker == partnerA){
                closerBalance = updateBalanceB;
                settlerBalance = getChannelBalance(channelId).sub256(updateBalanceB);                
            }
            else if (invoker == partnerB){
                closerBalance = updateBalanceA;
                settlerBalance = getChannelBalance(channelId).sub256(updateBalanceA);                
            }
        }

        // if updated nonce is larger than nonce+1 that closer provided nonce, determine closer provided invalid transaction, partner will also get closer assets
        else if (nonce > (closingNonce + 1)){
            closerBalance = 0;
            settlerBalance = getChannelBalance(channelId);
        }        
        
        bool callResult = address(trinityDataContract).call(bytes4(keccak256("closingSettle(bytes32,address,uint256,address,uint256)")),
                                                channelId,
                                                channelCloser,
                                                closerBalance,
                                                channelSettler,
                                                settlerBalance);

        require(callResult == true);
        
        emit UpdateTransaction(channelId, channelCloser, closerBalance, channelSettler, settlerBalance);        
    }

    function handleHTLCUpdateTx(address invoker,
                                bytes32 channelId, 
                                bytes32 lockHash) internal{
        
        address verifier;
        uint256 channelTotalBalance;
        bool withdrawLocked;
        bool callResult = false;
        
        (verifier, , , ,withdrawLocked) = trinityDataContract.getTimeLock(channelId,lockHash);

        require(withdrawLocked == true, "check withdraw status");
        
        require(invoker == verifier, "check verifier");
        
        channelTotalBalance = getChannelBalance(channelId);
              
        callResult = address(trinityDataContract).call(bytes4(keccak256("withdrawSettle(bytes32,address,uint256,uint256,bytes32)")),
                                                channelId,
                                                verifier,
                                                channelTotalBalance,
                                                0,
                                                lockHash);   
        channelTotalBalance = 0;                                    
        
        require(callResult == true);        
        
        emit WithdrawUpdate(channelId, invoker); 
    }    
    /*
     * Function: after apply close channnel, closer can withdraw assets until special settle window period time over
     * Parameters:
     *   partner: partner address that setup in same channel with sender;
     * Return:
         Null
    */
 
    function settleTransaction(bytes32 channelId) external whenNotPaused{
    
        uint256 expectedSettleBlock;
        uint256 closerBalance;
        uint256 settlerBalance;
        address channelCloser;
        address channelSettler;
    
        (, expectedSettleBlock,channelCloser,channelSettler,closerBalance,settlerBalance) = trinityDataContract.getClosingSettle(channelId); 
        
        // only chanel closer can call the function and channel status must be closing
        require(msg.sender == channelCloser, "check closer");
        
        require(expectedSettleBlock < block.number, "check settle time");        
        
        require(getChannelStatus(channelId) == CLOSING, "check channel status");
        
        bool callResult = address(trinityDataContract).call(bytes4(keccak256("closingSettle(bytes32,address,uint256,address,uint256)")),
                                                channelId,
                                                channelCloser,
                                                closerBalance,
                                                channelSettler,
                                                settlerBalance);

        require(callResult == true);        
        
        emit Settle(channelId, msg.sender, closerBalance, channelSettler, settlerBalance);
    }
 
     function withdraw(bytes32 channelId,
                       address sender,
                       address receiver,
                       uint256 lockTime ,
                       uint256 lockAmount,
                       bytes32 lockHash,
                       bytes partnerAsignature,
                       bytes partnerBsignature,
                       bytes32 secret) external {
                           
        bool withdrawLocked;

        require(verifyTimelock(channelId, 
                               sender, 
                               receiver, 
                               lockTime,
                               lockAmount,
                               lockHash,
                               partnerAsignature,
                               partnerBsignature) == true, "verify signature");
        
        require(msg.sender == sender || msg.sender == receiver, "check invoker");
        
        (, , , ,withdrawLocked) = trinityDataContract.getTimeLock(channelId,lockHash);

        require(withdrawLocked == false, "check withdraw status");
        
        require(lockAmount <= getChannelBalance(channelId));  
        
        handleWithdraw(msg.sender,channelId,sender,receiver,lockAmount,lockTime,lockHash,secret);
    }
    
    function handleWithdraw(address invoker,
                            bytes32 channelId,
                            address sender,
                            address receiver,
                            uint256 lockAmount,
                            uint256 lockTime,
                            bytes32 lockHash,
                            bytes32 secret) internal{
                                
        address withdrawer;
        address verifier;                        
        
        if (lockTime > block.number){
            require(invoker == receiver, "only receiver can apply before expiration");
            require(lockHash == keccak256(abi.encodePacked(secret)), "verify hash");
            withdrawer = receiver;
            verifier =  sender;
        }
        
        else{
            require(invoker == sender, "only sender can apply after expiration");
            withdrawer = sender;
            verifier =  receiver;
        }
        
        require(address(trinityDataContract).call(bytes4(keccak256("withdrawLocks(bytes32,bytes32,uint256,address,address)")),
                                                channelId,
                                                lockHash,
                                                lockAmount,
                                                verifier,
                                                withdrawer) == true);  
        
        emit Withdraw(channelId, invoker, lockHash, secret, getHtlcTimeoutBlock(channelId,lockHash));        
    }

    function withdrawSettle(bytes32 channelId,
                            bytes32 lockHash) external whenNotPaused{
                                
        address _withdrawer;
        uint256 lockAmount;
        uint256 lockTime;
        uint256 channelTotalBalance;
        bool withdrawLocked;
        
        (,_withdrawer,lockAmount,lockTime,withdrawLocked) = trinityDataContract.getTimeLock(channelId,lockHash);
        
        require(withdrawLocked == true, "check withdraw status");
        
        require(msg.sender == _withdrawer, "check caller");
        
        require(lockTime < block.number);
        
        require(lockAmount > 0);

        channelTotalBalance = getChannelBalance(channelId);
        channelTotalBalance = channelTotalBalance.sub256(lockAmount);

        bool callResult = address(trinityDataContract).call(bytes4(keccak256("withdrawSettle(bytes32,address,uint256,uint256,bytes32)")),
                                                channelId,
                                                msg.sender,
                                                lockAmount,
                                                channelTotalBalance,
                                                lockHash);   
                                                
        require(callResult == true);   
        
        emit WithdrawSettle(channelId, msg.sender, lockHash, lockAmount);
    }

    function () public { revert(); }
}