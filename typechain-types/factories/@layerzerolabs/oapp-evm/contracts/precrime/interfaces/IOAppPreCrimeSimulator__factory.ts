/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Interface, type ContractRunner } from "ethers";
import type {
  IOAppPreCrimeSimulator,
  IOAppPreCrimeSimulatorInterface,
} from "../../../../../../@layerzerolabs/oapp-evm/contracts/precrime/interfaces/IOAppPreCrimeSimulator";

const _abi = [
  {
    inputs: [],
    name: "OnlySelf",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "result",
        type: "bytes",
      },
    ],
    name: "SimulationResult",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "preCrimeAddress",
        type: "address",
      },
    ],
    name: "PreCrimeSet",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint32",
        name: "_eid",
        type: "uint32",
      },
      {
        internalType: "bytes32",
        name: "_peer",
        type: "bytes32",
      },
    ],
    name: "isPeer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            components: [
              {
                internalType: "uint32",
                name: "srcEid",
                type: "uint32",
              },
              {
                internalType: "bytes32",
                name: "sender",
                type: "bytes32",
              },
              {
                internalType: "uint64",
                name: "nonce",
                type: "uint64",
              },
            ],
            internalType: "struct Origin",
            name: "origin",
            type: "tuple",
          },
          {
            internalType: "uint32",
            name: "dstEid",
            type: "uint32",
          },
          {
            internalType: "address",
            name: "receiver",
            type: "address",
          },
          {
            internalType: "bytes32",
            name: "guid",
            type: "bytes32",
          },
          {
            internalType: "uint256",
            name: "value",
            type: "uint256",
          },
          {
            internalType: "address",
            name: "executor",
            type: "address",
          },
          {
            internalType: "bytes",
            name: "message",
            type: "bytes",
          },
          {
            internalType: "bytes",
            name: "extraData",
            type: "bytes",
          },
        ],
        internalType: "struct InboundPacket[]",
        name: "_packets",
        type: "tuple[]",
      },
    ],
    name: "lzReceiveAndRevert",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "oApp",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "preCrime",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_preCrime",
        type: "address",
      },
    ],
    name: "setPreCrime",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IOAppPreCrimeSimulator__factory {
  static readonly abi = _abi;
  static createInterface(): IOAppPreCrimeSimulatorInterface {
    return new Interface(_abi) as IOAppPreCrimeSimulatorInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): IOAppPreCrimeSimulator {
    return new Contract(
      address,
      _abi,
      runner
    ) as unknown as IOAppPreCrimeSimulator;
  }
}
