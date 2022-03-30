-include .env

all :; forge build
deploy :; forge create --rpc-url https://eth-goerli.alchemyapi.io/v2/_c0RnvXtlMznarePJQlVXIQNW_gPTmw3 --constructor-args ["0x392869b230D8c4F2439e3E7690823064844E68BA", "0x26773E7013DaD5CF558aB499DFdED94A7Cc5bEf2", "0xBb9B03462a7C9A1f80b348e956eDE9d53223c9B7"] 2  --private-key fd36c7695c6c788706ec152c33c4084728fbefeefed4578b6e2bc931bab7bc3a --from 0x392869b230D8c4F2439e3E7690823064844E68BA --etherscan-api-key AGNAWWWJ7K3VP8IGJQ7DP8SEGV6BY74Z88 src/Multisig.sol:Multisig


