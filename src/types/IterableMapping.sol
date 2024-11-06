// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Challenge, ChallengeCompletion } from "../types/DataTypes.sol";

library IterableMapping {
    struct ChallengesItMap {
        mapping(uint256 key => Challenge) values;
        uint256[] keys;
    }

    struct ChallengeCompletionsItMap {
        mapping(uint256 key => ChallengeCompletion) values;
        uint256[] keys;
    }

    //********************************************************************************************* */
    //                                     CHALLENGES
    //********************************************************************************************* */

    function set(ChallengesItMap storage self, uint256 key, Challenge memory value) internal returns (bool replaced) {
        if (self.values[key].id != 0) {
            replaced = true;
        }
        self.values[key] = value;
        self.keys.push(key);
    }

    function remove(ChallengesItMap storage self, uint256 key) internal returns (bool success) {
        if (self.values[key].id == 0) {
            return false;
        }
        delete self.values[key];
        delete self.keys[key];
        if (self.keys.length > 1) {
            self.keys[key] = self.keys[self.keys.length - 1];
        }
        self.keys.pop();
        return true;
    }

    function contains(ChallengesItMap storage self, uint256 key) internal view returns (bool) {
        return self.values[key].id != 0;
    }

    function get(ChallengesItMap storage self, uint256 key) internal view returns (Challenge storage) {
        return self.values[key];
    }

    function at(
        ChallengesItMap storage self,
        uint256 index
    )
        internal
        view
        returns (uint256 key, Challenge storage value)
    {
        key = self.keys[index];
        value = self.values[key];
    }

    function length(ChallengesItMap storage self) internal view returns (uint256) {
        return self.keys.length;
    }

    function values(ChallengesItMap storage self) internal view returns (Challenge[] memory result) {
        result = new Challenge[](self.keys.length);
        for (uint256 i = 0; i < self.keys.length; i++) {
            result[i] = self.values[self.keys[i]];
        }
        return result;
    }

    //********************************************************************************************* */
    //                                     CHALLENGE COMPLETIONS
    //********************************************************************************************* */

    function set(
        ChallengeCompletionsItMap storage self,
        uint256 key,
        ChallengeCompletion memory value
    )
        internal
        returns (bool replaced)
    {
        if (self.values[key].id != 0) {
            replaced = true;
        }
        self.values[key] = value;
        self.keys.push(key);
    }

    function remove(ChallengeCompletionsItMap storage self, uint256 key) internal returns (bool success) {
        if (self.values[key].id == 0) {
            return false;
        }
        delete self.values[key];
        delete self.keys[key];
        if (self.keys.length > 1) {
            self.keys[key] = self.keys[self.keys.length - 1];
        }
        self.keys.pop();
        return true;
    }

    function contains(ChallengeCompletionsItMap storage self, uint256 key) internal view returns (bool) {
        return self.values[key].id != 0;
    }

    function get(
        ChallengeCompletionsItMap storage self,
        uint256 key
    )
        internal
        view
        returns (ChallengeCompletion storage)
    {
        return self.values[key];
    }

    function at(
        ChallengeCompletionsItMap storage self,
        uint256 index
    )
        internal
        view
        returns (uint256 key, ChallengeCompletion storage value)
    {
        key = self.keys[index];
        value = self.values[key];
    }

    function length(ChallengeCompletionsItMap storage self) internal view returns (uint256) {
        return self.keys.length;
    }

    function values(
        ChallengeCompletionsItMap storage self
    )
        internal
        view
        returns (ChallengeCompletion[] memory result)
    {
        result = new ChallengeCompletion[](self.keys.length);
        for (uint256 i = 0; i < self.keys.length; i++) {
            result[i] = self.values[self.keys[i]];
        }
        return result;
    }
}
