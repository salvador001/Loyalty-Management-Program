// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LoyaltyProgram is ERC20("RewardCoin", "RC"), Ownable {
    uint256 public toBeMint;
    uint256 private incentive;
    uint256 private maxIncentive;

    uint8 private constant PROCESSED = 0;
    uint8 private constant RETURN = 1;
    uint8 private constant PENDING = 2;
    uint8 private constant PAID = 3;

    using SafeMath for uint256;    // safemath of uint256 to prevent overflow and underflows.
    using Counters for Counters.Counter;
    Counters.Counter private customerCount; 
    Counters.Counter private partnerCount;


    // initialize an initial incentive and maximum incentive values.
    constructor(uint256 _initIncentive, uint256 _initMaxIncentive) {
        _mint(msg.sender, 100 * 10**18);
        incentive = _initIncentive;
        maxIncentive = _initMaxIncentive;
    }


    // When 'toBeMint' is set and needs to be minted.    
    function mintCoin() public onlyOwner {
        _mint(msg.sender, toBeMint * 10**18);
        toBeMint = uint256(0);
        emit CoinsMinted(msg.sender, toBeMint * 10**18);
    }

    
    // When a specific amount needs to be minted.
    function mintCoin(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount * 10**18);
        emit CoinsMinted(msg.sender, amount * 10**18);
    }

    // Transfer funds from the contract owner to a specified recipient.
    function transferFund(address to, uint256 amount) public {
        transfer(to, amount * 10**18); 
        emit FundTransferred(msg.sender, to, amount * 10**18);
    }

    // Setter for 'incentive'  ONLY ADMIN 
    function setIncentive(uint256 _incentive) public onlyOwner {
        incentive = _incentive;
    }

    // Setter for 'maxIncentive' ONLY ADMIN 
    function setMaxIncentive(uint256 _maxIncentive) public onlyOwner {
        maxIncentive = _maxIncentive;
    }

    // Getter for 'incentive' 
    function getIncentive() public view returns (uint256) {
        return incentive;
    }

    // Getter for 'maxIncentive'
    function getMaxIncentive() public view returns (uint256) {
        return maxIncentive;
    }


    // struct to record transactions on chain
    struct Transaction {
        uint256 id;
        uint256 amount;
        uint256 time;
        uint8 status;
    }


    address[] public customers;
    address[] public partners;


    mapping(address => bool) public isCustomer;  // Mapping to track whether an address is a customer or not.
    mapping(address => bool) public isPartner;   // // Mapping to track whether an address is a parnter or not.

    mapping(address => Transaction[]) public transactions;

    // credit token to customer after refund and return policy period is over
    function creditTokens() public onlyOwner {
        for (uint256 i = 0; i < customers.length; i++) {
            creditIfTimePassed(customers[i]);
        }
    }

    // credit token to specific customer after refund and return policy period is over
    function creditIfTimePassed(address _customerAddress) private onlyOwner {
        uint256 totaltransactions = transactions[_customerAddress].length;
        uint256 amountToBeCredit = 0;
        for (uint256 i = 0; i < totaltransactions; i++) {
            if (
                transactions[_customerAddress][i].status == PENDING &&
                block.timestamp >= transactions[_customerAddress][i].time
            ) {
                amountToBeCredit += transactions[_customerAddress][i].amount;
                transactions[_customerAddress][i].status = PROCESSED;
            }
        }
        transferFund(_customerAddress, amountToBeCredit);
    }

    // veiw total customers to access the details
    function getTotalCustomerCount() public view returns (uint256) {
        return customerCount.current();
    }

    // ---------------------------- Event --------------------------------------------------
    event CustomerAdded(
        address indexed customerAddress
    );

    event TokensDebited(
        address indexed customerAddress,
        uint256 indexed transactionId,
        uint256 amount
    );

    event FundTransferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event CoinsMinted(
        address indexed minter,
        uint256 amount
    );

    

    // to check the msg sender is a customer
    modifier onlyCustomer() {
        require(isCustomer[msg.sender] == true, "Not a customer");
        _;
    }

     // to check the msg sender is a partner
    modifier onlyPartner() {
        require(isPartner[msg.sender] == true, "Not a partner");
        _;
    }


    // add Customer
    function addCustomer() public {
        require(isCustomer[msg.sender] == false, "Customer already exists");
        customers.push(msg.sender);
        isCustomer[msg.sender] = true;

        customerCount.increment();
        emit CustomerAdded(msg.sender);
    }

    // customer can use their reward tokens
    function debitToken(
        address to,
        uint256 _id,
        uint256 _amount
    ) public onlyCustomer {
        require(isCustomer[msg.sender] == true, "Customer not registered");
        require(balanceOf(msg.sender) > _amount, "Insufficient Balance");
        require(
            to == owner() || isPartner[to] == true,
            "Not authorised to debit token to the provided account"
        );
        transferFund(to, _amount);
        addDebitTransaction(msg.sender, _id, _amount);
        emit TokensDebited(msg.sender, _id, _amount);
    }

    // add customer debit transactions
    function addDebitTransaction(
        address _customerAddress,
        uint256 _id,
        uint256 _amount
    ) public {
        transactions[_customerAddress].push(
            Transaction({
                id: _id,
                amount: _amount,
                time: block.timestamp,
                status: PAID
            })
        );
    }

    
    // add Transaction to the customer
    function addTransaction(
        address _customer,
        uint256 _id,
        uint256 _amount,
        uint256 _timeToCredit
    ) public onlyCustomer {
        uint256 calAmount = _amount.div(100);
        calAmount = calAmount.mul(incentive);
        if (calAmount > maxIncentive) calAmount = maxIncentive;
        transactions[_customer].push(
            Transaction({
                id: _id,
                amount: calAmount,
                time: _timeToCredit,
                status: PENDING
            })
        );
        toBeMint += _amount;
    }

    // fetch all the transactions from the users
    function getTransaction(address _customerAddress)
        public
        view
        returns (Transaction[] memory)
    {
        return transactions[_customerAddress];
    }

    // get details of transactions using transaction id
    function getTransaction(address _customer, uint256 _id)
        public
        view
        returns (Transaction memory)
    {
        for (uint256 i = 0; i < transactions[_customer].length; i++) {
            if (transactions[_customer][i].id == _id) {
                return transactions[_customer][i];
            }
        }

        revert("Transaction not found");
    }

    // modify the transactions in case of return, refund and cancellation
    function cancelTransaction(address _customer, uint256 _id)
        public
        onlyCustomer
    {
        for (uint256 i = 0; i < transactions[_customer].length; i++) {
            if (transactions[_customer][i].id == _id) {
                transactions[_customer][i].amount = uint256(0);
                transactions[_customer][i].status = RETURN;
                return;
            }
        }

        revert("Transaction not found");
    }

    //----------------------------------- Partner Section ---------------------------------------------

    // Only Admin/Owner can add Partners
    function addPartner(address _partnerAddress) public onlyOwner {
        // Ensure the partner does not already exist
        require(isPartner[_partnerAddress] == false, "Partner already exists");

        partners.push(_partnerAddress);
        isPartner[_partnerAddress] = true;
        partnerCount.increment();
    }

   // Transaction between ADMIN and PARTNER
    struct PartnerTransaction {
        uint256 amount;
        uint256 timestamp;
    }

    // Transaction between PARTNER and CUSTOMER
    struct CustomerTransaction {
        address customerAddress;
        uint256 amount;
        uint256 timestamp;
    }

    // transaction between E-platform and Partner Brands for settlement
    mapping(address => PartnerTransaction[]) partnerTransactions;

    // transaction between Partner Brands and Their Loyal Customer
    mapping(address => CustomerTransaction[]) customerTransactions;

    // grant the requested token by the partner ONLY ADMIN
    function grantTokens(address _partnerAddress, uint256 _amount)
        public
        onlyOwner
    {
        transferFund(_partnerAddress, _amount);
        addPartnerTransaction(_partnerAddress, _amount);
    }

    // add the transactions between Platform and Partner
    function addPartnerTransaction(address _partnerAddress, uint256 _amount)
        public
        onlyOwner
    {
        partnerTransactions[_partnerAddress].push(
            PartnerTransaction({amount: _amount, timestamp: block.timestamp})
        );
    }

    // Get total partners count
    function getTotalPartnerCount() public view returns (uint256) {
        return partnerCount.current();
    }

    // fetch all the transaction between ADMIN and PARTNER
    function getPartnerTransaction(address _partnerAddress)
        public
        view
        returns (PartnerTransaction[] memory)
    {
        return partnerTransactions[_partnerAddress];
    }

    // fetch all the transaction between PARTNER and CUSTOMER
    function getPartnerCustomerTransaction(address _partnerAddress)
        public
        view
        returns (CustomerTransaction[] memory)
    {
        return customerTransactions[_partnerAddress];
    }

    // Partners can grant tokens to their loyal customers
    function payLoyalty(address _customerAddress, uint256 _amount)
        public
        onlyPartner
    {
        transferFund(_customerAddress, _amount);
        customerTransactions[msg.sender].push(
            CustomerTransaction({
                customerAddress: _customerAddress,
                amount: _amount,
                timestamp: block.timestamp
            })
        );

        emit FundTransferred(msg.sender, _customerAddress, _amount * 10**18);
    }
}
