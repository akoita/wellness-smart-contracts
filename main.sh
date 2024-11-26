#! /bin/bash

export ROOT_DIR=$(dirname "$(realpath "$0")")

source $ROOT_DIR/.env.example

function print_help {
    echo "Usage: main.sh [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy --local [--copy-artifacts]   Deploy to local network"
    echo "  deploy --testnet                    Deploy to testnet"
    echo "  --help                              Show this help message"
    echo ""
    echo "Options:"
    echo "  --copy-artifacts                    Copy deployment artifacts to frontend (only for local deployment)"
}

export COPY_ARTIFACTS=false

case "$1" in
    --help)
        print_help
        ;;
    deploy)
        case "$2" in
            --local)
                if [ "$3" == "--copy-artifacts" ]; then
                    export COPY_ARTIFACTS=true
                fi
                bash $ROOT_DIR/shell/deploy-local.sh
                ;;
            --testnet)
                bash $ROOT_DIR/shell/deploy-test.sh
                ;;
            *)
                echo "Invalid option for deploy. Use --local or --testnet."
                print_help
                ;;
        esac
        ;;
    *)
        echo "Invalid command. Use --help to see the list of available commands."
        print_help
        ;;
esac
