# Function Build

## Linux

```bash
$env:GOOS = "linux"
$env:GOARCH = "amd64"
go build -o transaction-api ./transaction-api/transaction-api.go
function azure functionapp publish <your-function-app-name> --force
```


## Windows

```bash
$env:GOOS = "windows"
$env:GOARCH = "amd64"
go build -o transaction-api.exe ./transaction-api/transaction-api.go
function azure functionapp publish <your-function-app-name> --force
```

