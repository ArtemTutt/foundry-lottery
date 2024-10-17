-include .env

build:; forge build
deploy:
	forge script script/DeployFundMe.s.sol --rpc-url 127.0.0.1:8545 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --broadcast
