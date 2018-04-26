pragma solidity 0.4.23;

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


contract ParsecPreICO is owned {
    /// @notice Use OpenZeppelin's SafeMath
    using SafeMath for uint256;

    /// @notice Define KYC states
    enum KycState {
        Undefined,
        Pending,
        Accepted,
        Declined
    }

    // ------------------------
    // --- Input parameters ---
    // ------------------------

    /// @notice Minimum ETH amount per transaction
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT = 0.01 ether;

    /// @notice Parsec ERC20 token address (from previously deployed contract)
    ParsecTokenERC20 private parsecToken;

    /// @notice This contract's hard cap (value in wei, 18 decimals)
    uint256 public hardCap;

    /// @notice Amount of Parsecs granted per 1 ETH (6 decimals)
    uint256 public parsecsPerEth;

    // ---------------------------
    // --- Power-up parameters ---
    // ---------------------------

    /// @notice Minimal amount of Parsecs to cover the hard cap
    uint256 public minimalAmountOfParsecs;

    /// @notice Keep track if contract is powered up (has enough Parsecs)
    bool public contractPoweredUp = false;

    // ---------------------------
    // --- State parameters ---
    // ---------------------------

    /// @notice Keep track if contract is started (permanently, works if contract is powered up) 
    bool public contractStarted = false;

    /// @notice Keep track if contract is finished (permanently, works if contract is started) 
    bool public contractFinished = false;

    /// @notice Keep track if contract is paused (transiently, works if contract started and not finished) 
    bool public contractPaused = false;

    // ------------------------
    // --- Funding tracking ---
    // ------------------------

    /// @notice Keep track of total amount of funding raised and passed KYC (available + withdrawn)
    uint256 public raisedFunding;
    
    /// @notice Keep track of funding amount available for withdraw
    uint256 public availableFunding;

    /// @notice Keep track of already withdrawn funding amount
    uint256 public withdrawnFunding;
    
    /// @notice Keep track of funding amount pending KYC check
    uint256 public pendingFunding;

    // ------------------------
    // --- Parsecs tracking ---
    // ------------------------

    /// @notice Keep track of spent Parsecs amount (transferred to participants)
    uint256 public spentParsecs;
    
    /// @notice Keep track of pending Parsecs amount (participant pending KYC)
    uint256 public pendingParsecs;

    // ----------------
    // --- Balances ---
    // ----------------

    /// @notice Keep track of all contributions per account passed KYC
    mapping (address => uint256) public contributionOf;

    /// @notice Keep track of all Parsecs granted to participants after they passed KYC
    mapping (address => uint256) public parsecsOf;

    /// @notice Keep track of all contributions pending KYC
    mapping (address => uint256) public pendingContributionOf;

    /// @notice Keep track of all Parsecs' rewards pending KYC
    mapping (address => uint256) public pendingParsecsOf;

    // -----------------------------------------
    // --- KYC (Know-Your-Customer) tracking ---
    // -----------------------------------------

    /// @notice Keep track of participants' KYC status
    mapping (address => KycState) public kycStatus;

    // --------------
    // --- Events ---
    // --------------

    /// @notice Log an event for each contributed amount passed KYC
    event LogContribution(address indexed sender, uint256 value, uint256 timestamp);

    /// @notice Log an event for each KYC-declined contribution
    event LogKycDecline(address indexed sender, uint256 value, uint256 timestamp);

    /**
     * Constructor function
     *
     * Initializes smart contract
     *
     * @param _tokenAddress The address of the previously deployed ParsecTokenERC20 contract
     * @param _hardCap Hard cap in ETH for this contract (value in wei, 18 decimals)
     * @param _parsecsPerEth The amount of Parsecs granted per 1 ETH (6 decimals)
     */
    function ParsecPreICO (address _tokenAddress, uint256 _hardCap, uint256 _parsecsPerEth) public {
        // Get Parsec ERC20 token instance
        parsecToken = ParsecTokenERC20(_tokenAddress);

        // Store hard cap and parsecs per ETH rate
        hardCap = _hardCap;
        parsecsPerEth = _parsecsPerEth;

        // Calculate minimal amount of Parsec credits to cover the hard cap
        uint256 value = hardCap.mul(parsecsPerEth);
        minimalAmountOfParsecs = value.div(1 ether);
    }

    /// @notice A participant sends a contribution to the contract's address
    ///         when contract is active and not paused
    /// @notice Only contributions above the MINIMUM_PARTICIPATION_AMOUNT are
    ///         accepted. Otherwise the transaction is rejected and contributed
    ///         amount is returned to the participant's account
    /// @notice A participant's contribution will be rejected if it exceeds
    ///         the hard cap
    /// @notice A participant's contribution will be rejected if the hard
    ///         cap is reached
    function () public payable {
        // Contract should be powered up
        require(contractPoweredUp);

        // A participant can send funds if:
        // - contract NOT started;
        require(contractStarted);        
        // - contract IS NOT finished;
        require(!contractFinished);
        // - contract IS NOT paused      
        require(!contractPaused);

        // Calculate maximum amount of ETH smart contract can accept
        uint256 maxAcceptableValue = hardCap.sub(raisedFunding);
        maxAcceptableValue = maxAcceptableValue.sub(pendingFunding);

        // Maximum acceptable value should not be less than minimum
        // participation amount and not greater than the hard cap
        require(maxAcceptableValue >= MINIMUM_PARTICIPATION_AMOUNT);
        require(maxAcceptableValue <= hardCap);

        // A participant cannot send less than the minimum amount
        // and not greater than maximal acceptable value
        require(msg.value >= MINIMUM_PARTICIPATION_AMOUNT);
        require(msg.value <= maxAcceptableValue);

        // Check if participant's KYC state is Undefined and set it to Pending
        if (kycStatus[msg.sender] == KycState.Undefined) {
            kycStatus[msg.sender] = KycState.Pending;
        }

        if (kycStatus[msg.sender] == KycState.Pending) {
            // KYC is Pending: register pending contribution
            addPendingContribution(msg.sender, msg.value);
        } else if (kycStatus[msg.sender] == KycState.Accepted) {
            // KYC is Accepted: register accepted contribution
            addAcceptedContribution(msg.sender, msg.value);
        } else {
            // KYC is Declined: revert transaction
            revert();
        }
    }

    /// @notice Check if contract has enough Parsecs to cover hard cap
    function ownerPowerUpContract() external onlyOwner {
        // Contract should not be powered up previously
        require(!contractPoweredUp);

        // Contract should have enough Parsec credits
        require(parsecToken.balanceOf(this) >= minimalAmountOfParsecs);

        // Raise contract power-up flag
        contractPoweredUp = true;
    }

    /// @notice Start contract (permanently)
    function ownerStartContract() external onlyOwner {
        // Contract should be powered up previously
        require(contractPoweredUp);

        // Contract should not be started previously
        require(!contractStarted);

        // Raise contract started flag
        contractStarted = true;
    }

    /// @notice Finish contract (permanently)
    function ownerFinishContract() external onlyOwner {
        // Contract should be started previously
        require(contractStarted);

        // Contract should not be finished previously
        require(!contractFinished);

        // Raise contract finished flag
        contractFinished = true;
    }

    /// @notice Pause contract (transiently)
    function ownerPauseContract() external onlyOwner {
        // Contract should be started previously
        require(contractStarted);

        // Contract should not be finished previously
        require(!contractFinished);

        // Contract should not be paused previously
        require(!contractPaused);

        // Raise contract paused flag
        contractPaused = true;
    }

    /// @notice Resume contract (transiently)
    function ownerResumeContract() external onlyOwner {
        // Contract should be paused previously
        require(contractPaused);

        // Unset contract paused flag
        contractPaused = false;
    }

    /// @notice Owner can withdraw available ETH anytime
    function ownerWithdrawEther(uint256 value) external onlyOwner {
        // Amount of ETH to withdraw should not exceed availableFunding
        require(value > 0);
        require(value <= availableFunding);

        // Decrease availableFunding by value
        availableFunding = availableFunding.sub(value);

        // Increase withdrawnFunding by value
        withdrawnFunding = withdrawnFunding.add(value);

        // Transfer ETH
        owner.transfer(value);
    }

    /// @notice Owner can withdraw Parsecs only after contract is finished
    function ownerWithdrawParsecs(uint256 value) external onlyOwner {
        // Contract should be finished before any Parsecs could be withdrawn
        require(contractFinished);

        // Get smart contract balance in Parsecs
        uint256 parsecBalance = parsecToken.balanceOf(this);

        // Calculate maximal amount to withdraw
        uint256 maxAmountToWithdraw = parsecBalance.sub(pendingParsecs);

        // Maximal amount to withdraw should be greater than zero
        require(maxAmountToWithdraw > 0);

        // Amount of Parsecs to withdraw should not exceed maxAmountToWithdraw
        require(value > 0);
        require(value <= maxAmountToWithdraw);

        // Transfer parsecs
        parsecToken.transfer(owner, value);
    }
 
    /// @dev Accept participant's KYC
    function ownerAcceptKyc(address participant) external onlyOwner {
        // Participant's KYC status should be Pending
        require(kycStatus[participant] == KycState.Pending);

        // Set participant's KYC status to Accepted
        kycStatus[participant] = KycState.Accepted;

        // Get amounts of pending ETH and Parsecs
        uint256 pendingAmountOfEth = pendingContributionOf[participant];
        uint256 pendingAmountOfParsecs = pendingParsecsOf[participant];

        // Decrease pendingFunding by pendingAmountOfEth
        pendingFunding = pendingFunding.sub(pendingAmountOfEth);

        // Decrease pendingParsecs by pendingAmountOfParsecs
        pendingParsecs = pendingParsecs.sub(pendingAmountOfParsecs);

        // Add accepted contribution
        addAcceptedContribution(participant, pendingAmountOfEth);
    }

    /// @dev Decline participant's KYC
    function ownerDeclineKyc(address participant) external onlyOwner {
        // Participant's KYC status should be Pending
        require(kycStatus[participant] == KycState.Pending);

        // Set participant's KYC status to Declined
        kycStatus[participant] = KycState.Declined;

        // Get amounts of pending ETH and Parsecs
        uint256 pendingAmountOfEth = pendingContributionOf[participant];
        uint256 pendingAmountOfParsecs = pendingParsecsOf[participant];

        // Decrease pending contribution by pendingAmountOfEth
        pendingContributionOf[participant] = pendingContributionOf[participant].sub(pendingAmountOfEth);

        // Decrease pending Parsecs reward by pendingAmountOfParsecs
        pendingParsecsOf[participant] = pendingParsecsOf[participant].sub(pendingAmountOfParsecs);

        // Decrease pendingFunding by pendingAmountOfEth
        pendingFunding = pendingFunding.sub(pendingAmountOfEth);

        // Decrease pendingParsecs by pendingAmountOfParsecs
        pendingParsecs = pendingParsecs.sub(pendingAmountOfParsecs);

        // Log an event of the participant's KYC decline
        LogKycDecline(participant, pendingAmountOfEth, now);

        // Transfer ETH back to participant
        participant.transfer(pendingAmountOfEth);
    }

    /// @dev Register pending contribution
    function addPendingContribution(address participant, uint256 value) private {
        // Calculate amount of Parsecs for reward
        uint256 parsecAmount = calculateReward(value);

        // Participant's pending contribution is increased by value
        pendingContributionOf[participant] = pendingContributionOf[participant].add(value);

        // Parsecs pending to participant increased by parsecAmount
        pendingParsecsOf[participant] = pendingParsecsOf[participant].add(parsecAmount);

        // Increase pending funding by value
        pendingFunding = pendingFunding.add(value);

        // Increase pending Parsecs by parsecAmount
        pendingParsecs = pendingParsecs.add(parsecAmount);
    }

    /// @dev Register accepted contribution
    function addAcceptedContribution(address participant, uint256 value) private {
        // Calculate amount of Parsecs for reward
        uint256 parsecAmount = calculateReward(value);

        // Participant's contribution is increased by value
        contributionOf[participant] = contributionOf[participant].add(value);

        // Parsecs rewarded to participant increased by parsecAmount
        parsecsOf[participant] = parsecsOf[participant].add(parsecAmount);

        // Increase total raised funding by value
        raisedFunding = raisedFunding.add(value);

        // Increase available funding by value
        availableFunding = availableFunding.add(value);

        // Increase spent Parsecs by parsecAmount
        spentParsecs = spentParsecs.add(parsecAmount);

        // Log an event of the participant's contribution
        LogContribution(participant, value, now);

        // Transfer Parsecs
        parsecToken.transfer(participant, parsecAmount);
    }

    /// @dev Calculate amount of Parsecs to grant for ETH contribution
    function calculateReward(uint256 value) private view returns (uint256 amount) {
        uint256 reward = value.mul(parsecsPerEth);
        return reward.div(1 ether);
    }
}