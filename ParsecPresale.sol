pragma solidity ^0.4.16;

import "./ParsecTokenERC20.sol";

contract ParsecPresale is owned {
    // -------------------------------------------------------------------------------------
    // TODO Before deployment of contract to Mainnet
    // # Security checklists to use in each review:
    // - Consensys checklist https://github.com/ConsenSys/smart-contract-best-practices
    // - Roland Kofler's checklist https://github.com/rolandkofler/ether-security
    // - Read all of the code and use creative and lateral thinking to discover bugs
    // -------------------------------------------------------------------------------------

    // Minimum and maximum goals of the presale
    uint256 public constant PRESALE_MINIMUM_FUNDING =  287.348 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 1887.348 ether;

    // Minimum amount per transaction for public participants
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT = 0.5 ether;

    // Total whitelisted funding amount
    uint256 public constant TOTAL_WHITELISTED_FUNDING = 1 ether;        // FIXME: set a valid value!

    // Public presale period
    uint256 public constant PRESALE_START_DATE = 1516795200;            // 2018-01-24 12:00:00 UTC
    uint256 public constant PRESALE_END_DATE = 1517400000;              // 2018-01-31 12:00:00 UTC

    // Second and third day of pre-sale timestamps
    uint256 public constant PRESALE_SECOND_DAY_START = 1516881600;      // 2018-01-25 12:00:00 UTC
    uint256 public constant PRESALE_THIRD_DAY_START = 1516968000;       // 2018-01-26 12:00:00 UTC

    // Owner can clawback after a date in the future, so no ethers remain trapped in the contract.
    // This will only be relevant if the minimum funding level is not reached
    uint256 public constant OWNER_CLAWBACK_DATE = 1519128000;           // 2018-02-20 12:00:00 UTC

    // Pledgers can withdraw their Parsec credits after a date in the future.
    // This will only be relevant if the minimum funding level is reached
    uint256 public constant TOKEN_WITHDRAWAL_START_DATE = 1525176000;   // 2018-05-01 12:00:00 UTC
    uint256 public constant TOKEN_WITHDRAWAL_END_DATE = 1527854400;     // 2018-06-01 12:00:00 UTC

    // Minimal amount of Parsec credits to be avaibale on this contract balance
    // in order to grant credits for all possible participant contributions
    uint256 public constant PARSEC_CREDITS_MINIMAL_AMOUNT = 3549000000;

    // Amount of Parsec credits to be granted per ether
    uint256 public constant PARSEC_CREDITS_PER_ETHER = 1690000;

    // It amount of transfer is greater or equal to this threshold,
    // additional bonus Parsec credits will be granted
    uint256 public constant BONUS_THRESHOLD = 50 ether;

    // Keep track of total funding amount
    uint256 public totalFunding;

    // Keep track of total whitelisted funding amount
    uint256 public totalWhitelistedFunding;

    // Keep track of granted Parsec credits amount
    uint256 public grantedParsecCredits;

    // Keep track of spent Parsec credits amount
    uint256 public spentParsecCredits;

    // Keep track if unspent Parsec credits were withdrawn
    bool public unspentCreditsWithdrawn = false;

    // Keep track if unclaimed Parsec credits were withdrawn
    bool public unclaimedCreditsWithdrawn = false;

    // Keep track if unclaimed Parsec credits were clawbacked
    bool public creditsClawbacked = false;

    /// @notice Keep track of all participants contributions, including both the
    ///         preallocation and public phases
    /// @dev Name complies with ERC20 token standard, etherscan for example will recognize
    ///      this and show the balances of the address
    mapping (address => uint256) public balanceOf;

    /// @notice Keep track of Parsec credits to be granted to participants.
    mapping (address => uint256) public creditBalanceOf;

    /// @notice Define whitelisted addresses and sums for the first 2 days of pre-sale.
    mapping (address => uint256) public whitelist;

    /// @notice Log an event for each funding contributed during the public phase
    /// @notice Events are not logged when the constructor is being executed during
    ///         deployment, so the preallocations will not be logged
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);

    // Parsec ERC20 token contract (from previously deployed address)
    ParsecTokenERC20 private parsecToken = ParsecTokenERC20(0x4444444444444444444444444444444444444444); // FIXME: set to a valid address

    function ParsecPresale () public payable {
        // FIXME: add REAL whitelisted amounts
        /*
        addToWhitelist(0xe902741cD4666E4023b7E3AB46D3DE2985c996f1, 1 ether);
        assert(TOTAL_WHITELISTED_FUNDING == totalWhitelistedFunding);
        */
    }

    /// @notice A participant sends a contribution to the contract's address
    ///         between the PRESALE_START_DATE and the PRESALE_END_DATE
    /// @notice Only contributions above the MINIMUM_PARTICIPATION_AMOUNT are accepted.
    ///         Otherwise the transaction is rejected and contributed amount is returned
    ///         to the participant's account
    /// @notice A participant's contribution will be rejected if the presale
    ///         has been funded to the maximum amount
    function () public payable {
        // A participant cannot send funds before the presale start date
        require(now >= PRESALE_START_DATE);

        // A participant cannot send funds after the presale end date
        require(now < PRESALE_END_DATE);

        // Contract should have enough Parsec credits
        require(parsecToken.balanceOf(this) >= PARSEC_CREDITS_MINIMAL_AMOUNT);

        // A participant cannot send less than the minimum amount
        require(msg.value >= MINIMUM_PARTICIPATION_AMOUNT);

        // Contract logic for transfers relies on current date and time.
        if (now >= PRESALE_START_DATE && now < PRESALE_SECOND_DAY_START) {
            // Trasfer logic for the 1st day of pre-sale.
            // Allow to transfer exact whitelisted sum for whitelisted addresses.
            require(whitelist[msg.sender] == msg.value);
            require(balanceOf[msg.sender] == 0);
        } else if (now >= PRESALE_SECOND_DAY_START && now < PRESALE_THIRD_DAY_START) {
            // Trasfer logic for the 2nd day of pre-sale.
            // Allow to transfer any sum within contract max cap for whitelisted addresses.
            require(whitelist[msg.sender] != 0);
        }

        // A participant cannot send funds if the presale has been reached the maximum funding amount
        require(safeIncrement(totalFunding, msg.value) <= PRESALE_MAXIMUM_FUNDING);

        // Register the participant's contribution
        addBalance(msg.sender, msg.value);

        // Grant Parsec credits according to participant's contribution
        grantCreditsForParticipation(msg.sender, msg.value);
    }

    /// @notice The owner can withdraw ethers only if the minimum funding level has been reached
    //          and pre-sale is over
    function ownerWithdraw() external onlyOwner {
        // The owner cannot withdraw until pre-sale ends
        require(now >= PRESALE_END_DATE);

        // The owner cannot withdraw if the presale did not reach the minimum funding amount
        require(totalFunding >= PRESALE_MINIMUM_FUNDING);

        // Withdraw the total funding amount
        assert(owner.send(totalFunding));
    }

    /// @notice The owner can withdraw unspent Parsec credits if the minimum funding level has been
    ///         reached and pre-sale is over
    function ownerWithdrawUnspentCredits() external onlyOwner {
        // The owner cannot withdraw unspent Parsec credits until pre-sale ends
        require(now >= PRESALE_END_DATE);

        // The owner cannot withdraw if the pre-sale did not reach the minimum funding amount
        require(totalFunding >= PRESALE_MINIMUM_FUNDING);

        // The owner cannot withdraw unspent Parsec credits more than once
        require(unspentCreditsWithdrawn == false);

        // Transfer unspent Parsec credits back to pre-sale contract owner
        uint256 unspentAmount = safeDecrement(parsecToken.balanceOf(this), grantedParsecCredits);
        parsecToken.transfer(owner, unspentAmount);
        unspentCreditsWithdrawn = true;
    }

    function ownerWithdrawUnclaimedCredits() external onlyOwner {
        // The owner cannot withdraw unclaimed Parsec credits until token withdrawal period ends
        require(now >= TOKEN_WITHDRAWAL_END_DATE);

        // The owner cannot withdraw if the presale did not reach the minimum funding amount
        require(totalFunding >= PRESALE_MINIMUM_FUNDING);

        // The owner cannot withdraw unclaimed Parsec credits more than once
        require(unclaimedCreditsWithdrawn == false);

        // Transfer unclaimed Parsec credits back to pre-sale contract owner
        parsecToken.transfer(owner, parsecToken.balanceOf(this));
        unclaimedCreditsWithdrawn = true;
    }

    /// @notice The participant will need to withdraw their Parsec credits if minimal pre-sale amount
    ///         was reached and date between TOKEN_WITHDRAWAL_START_DATE and TOKEN_WITHDRAWAL_END_DATE
    function participantClaimCredits() external {
        // Participant can withdraw Parsec credits only during token withdrawal period
        require(now >= TOKEN_WITHDRAWAL_START_DATE);
        require(now < TOKEN_WITHDRAWAL_END_DATE);

        // Participant cannot withdraw Parsec credits if the minimum funding amount has not been reached
        require(totalFunding >= PRESALE_MINIMUM_FUNDING);

        // Participant can only withdraw Parsec credits if granted amount exceeds zero
        require(creditBalanceOf[msg.sender] > 0);

        // Give allowance for participant to withdraw certain amount of Parsec credits
        parsecToken.approve(msg.sender, creditBalanceOf[msg.sender]);

        // Update amount of Parsec credits spent
        spentParsecCredits = safeIncrement(spentParsecCredits, creditBalanceOf[msg.sender]);

        // Participant's Parsec credit balance is reduced to zero
        creditBalanceOf[msg.sender] = 0;
    }

    /// @notice The participant will need to withdraw their funds from this contract if
    ///         the presale has not achieved the minimum funding level
    function participantWithdrawIfMinimumFundingNotReached(uint256 value) external {
        // Participant cannot withdraw before the presale ends
        require(now >= PRESALE_END_DATE);

        // Participant cannot withdraw if the minimum funding amount has been reached
        require(totalFunding < PRESALE_MINIMUM_FUNDING);

        // Participant can only withdraw an amount up to their contributed balance
        require(balanceOf[msg.sender] >= value);

        // Participant's balance is reduced by the claimed amount.
        balanceOf[msg.sender] = safeDecrement(balanceOf[msg.sender], value);

        // Send ethers back to the participant's account
        assert(msg.sender.send(value));
    }

    /// @notice The owner can clawback any ethers after a date in the future, so no
    ///         ethers remain trapped in this contract. This will only be relevant
    ///         if the minimum funding level is not reached
    function ownerClawback() external onlyOwner {
        // Minimum funding amount has not been reached
        require(totalFunding < PRESALE_MINIMUM_FUNDING);

        // The owner cannot withdraw before the clawback date
        require(now >= OWNER_CLAWBACK_DATE);

        // Send remaining funds back to the owner
        assert(owner.send(this.balance));
    }

    /// @notice The owner can clawback any unspent Parsec credits after a date in the future,
    ///         so no Parsec credits remain trapped in this contract. This will only be relevant
    ///         if the minimum funding level is not reached
    function ownerClawbackCredits() external onlyOwner {
        // Minimum funding amount has not been reached
        require(totalFunding < PRESALE_MINIMUM_FUNDING);

        // The owner cannot withdraw before the clawback date
        require(now >= OWNER_CLAWBACK_DATE);

        // The owner cannot clawback unclaimed Parsec credits more than once
        require(creditsClawbacked == false);

        // Transfer clawbacked Parsec credits back to pre-sale contract owner
        parsecToken.transfer(owner, parsecToken.balanceOf(this));
        creditsClawbacked = true;
    }

    /// @dev Keep track of participants contributions and the total funding amount
    function addBalance(address participant, uint256 value) private {
        // Participant's balance is increased by the sent amount
        balanceOf[participant] = safeIncrement(balanceOf[participant], value);

        // Keep track of the total funding amount
        totalFunding = safeIncrement(totalFunding, value);

        // Log an event of the participant's contribution
        LogParticipation(participant, value, now);
    }

    /// @dev Keep track of whitelisted participants contributions
    function addToWhitelist(address participant, uint256 value) private {
        // Participant's balance is increased by the sent amount
        whitelist[participant] = safeIncrement(whitelist[participant], value);

        // Keep track of the total whitelisted funding amount
        totalWhitelistedFunding = safeIncrement(totalWhitelistedFunding, value);
    }

    function grantCreditsForParticipation(address participant, uint256 etherAmount) private {
        // Add bonus 5% if contributed amount is greater or equal to bonus threshold
        uint256 multiplier = etherAmount >= BONUS_THRESHOLD ? 105 : 100;
        uint256 divisor = 100;

        // Calculate amount of Parsec credits to grant to contributor
        uint256 creditsToGrant = (multiplier * etherAmount * PARSEC_CREDITS_PER_ETHER) / (divisor * 1 ether);

        // Check if contract has enough Parsec credits
        require((parsecToken.balanceOf(this) - grantedParsecCredits) >= creditsToGrant);

        // Add Parsec credits amount to participant's credit balance
        creditBalanceOf[participant] = safeIncrement(creditBalanceOf[participant], creditsToGrant);

        // Add Parsec credits amount to total granted credits
        grantedParsecCredits = safeIncrement(grantedParsecCredits, creditsToGrant);
    }

    /// @dev Add a number to a base value.
    ///      Detect overflows by checking the result is larger than the original base value.
    function safeIncrement(uint256 base, uint256 increment) private pure returns (uint256) {
        uint256 result = base + increment;
        assert(result >= base);
        return result;
    }

    /// @dev Subtract a number from a base value.
    ///      Detect underflows by checking that the result is smaller than the original base value.
    function safeDecrement(uint256 base, uint256 increment) private pure returns (uint256) {
        uint256 result = base - increment;
        assert(result <= base);
        return result;
    }
}
