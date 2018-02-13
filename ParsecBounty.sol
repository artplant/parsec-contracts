pragma solidity 0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ParsecTokenERC20 {
    // Public variables of the token
    string public constant name = "Parsec Credits";
    string public constant symbol = "PRSC";
    uint8 public decimals = 6;
    uint256 public initialSupply = 30856775800;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function ParsecTokenERC20() public {
        // Update total supply with the decimal amount
        totalSupply = initialSupply * 10 ** uint256(decimals);

        // Give the creator all initial tokens
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);

        // Check if the sender has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the sender
        balanceOf[_from] -= _value;

        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);

        // Subtract from the sender
        balanceOf[msg.sender] -= _value;

        // Updates totalSupply
        totalSupply -= _value;

        // Notify clients about burned tokens
        Burn(msg.sender, _value);

        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Check if the targeted balance is enough
        require(balanceOf[_from] >= _value);

        // Check allowance
        require(_value <= allowance[_from][msg.sender]);

        // Subtract from the targeted balance
        balanceOf[_from] -= _value;

        // Subtract from the sender's allowance
        allowance[_from][msg.sender] -= _value;

        // Update totalSupply
        totalSupply -= _value;

        // Notify clients about burned tokens
        Burn(_from, _value);

        return true;
    }
}

/**
 * @title Parsec Frontiers bounty reward contract
 *
 * @author Maxim Pushkar
 */
contract ParsecBounty is owned {
    // Use OpenZeppelin's SafeMath
    using SafeMath for uint256;

    // Claim period. During this period the registered accounts can claim their Parsec credits
    uint256 public constant CLAIM_START_DATE = 1525176000;              // 2018-05-01 12:00:00 UTC
    uint256 public constant CLAIM_END_DATE = 1533124800;                // 2018-08-01 12:00:00 UTC

    // Amount of Parsec credits required for all bounties
    uint256 public constant REQUIRED_CREDITS_AMOUNT = 400000000000000;  // 400000000.000000 PRSC

    // Keep track of total amount of Parsec credits to be claimed
    uint256 public totalAmountToClaim;

    // Keep track of amount of Parsec credits actually claimed
    uint256 public actuallyClaimedAmount;

    // Keep track if contract is powered up
    bool public contractPoweredUp = false;

    // Keep track if bounty chunk 1 / 3 is already added
    bool public chunk1IsAdded = false;

    // Keep track if bounty chunk 2 / 3 is already added
    bool public chunk2IsAdded = false;

    // Keep track if bounty chunk 3 / 3 is already added
    bool public chunk3IsAdded = false;

    // Keep track of all registered bounties
    mapping (address => uint256) public bountyOf;

    // Parsec ERC20 token contract (from previously deployed address)
    ParsecTokenERC20 private parsecToken;

    // Log an event for each claimed bounty during the claim period
    event LogBountyClaim(address indexed sender, uint256 value, uint256 timestamp);  

    function ParsecBounty (address tokenAddress) public {
        // Get Parsec ERC20 token instance
        parsecToken = ParsecTokenERC20(tokenAddress);
    }

    /// @notice Add bounty chunk 1 / 3
    function addBountyChunk1() external onlyOwner {
        // Bounty chunk can be added only once
        require(!chunk1IsAdded);

        // Register bounties
        // registerBounty(0x2C66aDd04950eE3235fd3EC6BcB2577c88d804E4, 0.5 ether);
  
        // Raise chunk added flag
        chunk1IsAdded = true;
    }

    /// @notice Add bounty chunk 2 / 3
    function addBountyChunk2() external onlyOwner {
        // Bounty chunk can be added only once
        require(!chunk2IsAdded);

        // Register bounties
        // registerBounty(0x2C66aDd04950eE3235fd3EC6BcB2577c88d804E4, 0.5 ether);

        // Raise chunk added flag
        chunk2IsAdded = true;
    }

    /// @notice Add bounty chunk 3 / 3
    function addBountyChunk3() external onlyOwner {
        // Bounty chunk can be added only once
        require(!chunk3IsAdded);

        // Register bounties
        // registerBounty(0x2C66aDd04950eE3235fd3EC6BcB2577c88d804E4, 0.5 ether);

        // Raise chunk added flag
        chunk3IsAdded = true;
    }

    /// @notice Power-up current bounty contract
    function powerUpContract() external onlyOwner {
        // Contract can be powered up only once
        require(!contractPoweredUp);

        // Get balance of this contract account in Parsec credits
        uint256 currentBalance = parsecToken.balanceOf(this);

        // Check if contract balance is equal or greated than `REQUIRED_CREDITS_AMOUNT`
        require(currentBalance >= REQUIRED_CREDITS_AMOUNT);

        // Check if bounty chunk 1 / 3 is added
        require(chunk1IsAdded);

        // Check if bounty chunk 2 / 3 is added
        require(chunk2IsAdded);

        // Check if bounty chunk 3 / 3 is added
        require(chunk3IsAdded);

        // Raise contract powered-up flag
        contractPoweredUp = true;
    }

    /// @notice The owner can withdraw unclaimed Parsec credits when claim period is over
    function ownerWithdrawUnclaimedCredits() external onlyOwner {
        // The owner cannot withdraw unclaimed Parsec credits until claim period is over
        require(now >= CLAIM_END_DATE);

        // Get balance of this contract account in Parsec credits
        uint256 currentBalance = parsecToken.balanceOf(this);

        // The owner cannot withdraw unclaimed Parsec credits if there are none
        require(currentBalance > 0);

        // Transfer unclaimed Parsec credits back to this contract owner
        parsecToken.transfer(owner, currentBalance);
    }

    /// @notice Participant can claim bounty in Parsec credits during claim period only
    function participantClaimCredits() external {
        // Check if claim period is active
        require(now >= CLAIM_START_DATE);
        require(now < CLAIM_END_DATE);

        // Get bounty amount for current participant
        uint256 bountyAmount = bountyOf[msg.sender];

        // There should be something to claim
        require(bountyAmount > 0);

        // Participant's bounty in Parsec credits is set to zero
        bountyOf[msg.sender] = 0;

        // Update amount of Parsec credits actually claimed
        actuallyClaimedAmount = actuallyClaimedAmount.add(bountyAmount);

        // Log bounty claim
        LogBountyClaim(msg.sender, bountyAmount, now);

        // Transfer Parsec credits to participant
        parsecToken.transfer(msg.sender, bountyAmount);
    }

    /// @notice Register bounty
    function registerBounty(address participant, uint256 value) private {
        // Participant's bounty is increased by `value`
        bountyOf[participant] = bountyOf[participant].add(value);

        // Keep track of the total amount of Parsec credits to claim
        totalAmountToClaim = totalAmountToClaim.add(value);
    }
}