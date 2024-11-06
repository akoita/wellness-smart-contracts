// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { WellnessHome } from "../src/WellnessHome.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WellnessHomeHarness is WellnessHome {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address owner) WellnessHome(owner) { }

    function partnerRegistrationRequestExists(address partner) public view returns (bool) {
        return partnerRegistrationRequests.contains(partner);
    }
}
