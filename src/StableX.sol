// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract StableX {
    /**
     * Token metadata
     */
    string private _name;
    string private _symbol;
    uint8 private constant DECIMALS = 18;
    uint256 private _totalSupply;
    uint256 private immutable i_maxSupply;

    string private constant TOKEN_NAME = "StableX";
    string private constant TOKEN_SYMBOL = "STX";

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * Ownership and access control
     */
    address private _owner;
    mapping(address => bool) private _minters;
    mapping(address => bool) private _blacklisters;
    mapping(address => bool) private _blacklisted;

    /**
     * Standard Events
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Ownership Events
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Role Events
     */
    event MinterGranted(address indexed account, address indexed grantedBy);
    event MinterRevoked(address indexed account, address indexed revokedBy);
    event BlacklisterGranted(address indexed account, address indexed grantedBy);
    event BlacklisterRevoked(address indexed account, address indexed revokedBy);

    /**
     * Blacklist Events
     */
    event AddressBlacklisted(address indexed account, address indexed blacklistedBy);
    event AddressUnblacklisted(address indexed account, address indexed removedBy);

    /**
     * Custom Errors
     */
    error StableX__ZeroAddress();
    error StableX__InsufficientBalance(address account, uint256 balance, uint256 needed);
    error StableX__InsufficientAllowance(address owner, address spender, uint256 allowance, uint256 needed);
    error StableX__CapExceeded(uint256 currentSupply, uint256 mintAmount, uint256 cap);
    error StableX__Unauthorized(address caller);
    error StableX__Blacklisted(address account);
    error StableX__AlreadyBlacklisted(address account);
    error StableX__NotBlacklisted(address account);

    /**
     * Modifiers
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert StableX__Unauthorized(msg.sender);
        }
        _;
    }

    modifier onlyMinter() {
        if (!_minters[msg.sender]) {
            revert StableX__Unauthorized(msg.sender);
        }
        _;
    }

    modifier onlyBlacklister() {
        if (!_blacklisters[msg.sender]) {
            revert StableX__Unauthorized(msg.sender);
        }
        _;
    }

    constructor(uint256 maxSupply, uint256 initialMint) {
        if (maxSupply < initialMint) {
            revert StableX__CapExceeded(0, initialMint, maxSupply);
        }
        _name = TOKEN_NAME;
        _symbol = TOKEN_SYMBOL;
        i_maxSupply = maxSupply;
        _totalSupply = initialMint;
        _owner = msg.sender;
        _minters[msg.sender] = true;
        _blacklisters[msg.sender] = true;
        _balances[msg.sender] = initialMint;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * Ownership Functions
     */

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert StableX__ZeroAddress();
        }
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    /**
     * Core Functions
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        if (to == address(0)) {
            revert StableX__ZeroAddress();
        }
        if (_blacklisted[msg.sender]) {
            revert StableX__Blacklisted(msg.sender);
        }
        if (_blacklisted[to]) {
            revert StableX__Blacklisted(to);
        }
        if (_balances[msg.sender] < amount) {
            revert StableX__InsufficientBalance(msg.sender, _balances[msg.sender], amount);
        }
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        if (spender == address(0)) {
            revert StableX__ZeroAddress();
        }
        if (_blacklisted[msg.sender]) {
            revert StableX__Blacklisted(msg.sender);
        }
        if (_blacklisted[spender]) {
            revert StableX__Blacklisted(spender);
        }
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from == address(0) || to == address(0)) {
            revert StableX__ZeroAddress();
        }
        if (_blacklisted[msg.sender]) {
            revert StableX__Blacklisted(msg.sender);
        }
        if (_blacklisted[from]) {
            revert StableX__Blacklisted(from);
        }
        if (_blacklisted[to]) {
            revert StableX__Blacklisted(to);
        }
        if (_balances[from] < amount) {
            revert StableX__InsufficientBalance(from, _balances[from], amount);
        }
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * Roles Functions
     */
    function grantMinter(address account) external onlyOwner {
        if (account == address(0)) {
            revert StableX__ZeroAddress();
        }
        _minters[account] = true;
        emit MinterGranted(account, msg.sender);
    }

    function revokeMinter(address account) external onlyOwner {
        if (account == address(0)) {
            revert StableX__ZeroAddress();
        }
        _minters[account] = false;
        emit MinterRevoked(account, msg.sender);
    }

    function grantBlacklister(address account) external onlyOwner {
        if (account == address(0)) {
            revert StableX__ZeroAddress();
        }
        _blacklisters[account] = true;
        emit BlacklisterGranted(account, msg.sender);
    }

    function revokeBlacklister(address account) external onlyOwner {
        if (account == address(0)) {
            revert StableX__ZeroAddress();
        }
        _blacklisters[account] = false;
        emit BlacklisterRevoked(account, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        if (to == address(0)) {
            revert StableX__ZeroAddress();
        }
        if (_blacklisted[to]) {
            revert StableX__Blacklisted(to);
        }
        if (_totalSupply + amount > i_maxSupply) {
            revert StableX__CapExceeded(_totalSupply, amount, i_maxSupply);
        }
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        if (_blacklisted[msg.sender]) {
            revert StableX__Blacklisted(msg.sender);
        }
        if (_balances[msg.sender] < amount) {
            revert StableX__InsufficientBalance(msg.sender, _balances[msg.sender], amount);
        }
        _burn(msg.sender, amount);
    }

    /**
     * Blacklist Functions
     */
    function blacklist(address account) external onlyBlacklister {
        if (account == address(0)) {
            revert StableX__ZeroAddress();
        }
        if (_blacklisted[account]) {
            revert StableX__AlreadyBlacklisted(account);
        }
        _blacklisted[account] = true;
        emit AddressBlacklisted(account, msg.sender);
    }

    function removeFromBlacklist(address account) external onlyBlacklister {
        if (account == address(0)) {
            revert StableX__ZeroAddress();
        }
        if (!_blacklisted[account]) {
            revert StableX__NotBlacklisted(account);
        }
        _blacklisted[account] = false;
        emit AddressUnblacklisted(account, msg.sender);
    }

    /**
     * Helper Functions
     */
    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];

        if (currentAllowance < amount) {
            revert StableX__InsufficientAllowance(owner, spender, currentAllowance, amount);
        }

        if (currentAllowance != type(uint256).max) {
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    /**
     * Public View Functions
     */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    function isBlacklister(address account) public view returns (bool) {
        return _blacklisters[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }
}
