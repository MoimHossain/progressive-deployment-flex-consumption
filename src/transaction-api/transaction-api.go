package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

type InvokeResponse struct {
	Outputs     map[string]interface{} `json:"Outputs"`
	Logs        []string               `json:"Logs"`
	ReturnValue interface{}            `json:"ReturnValue"`
}

type HttpResponse struct {
	StatusCode int                    `json:"statusCode"`
	Body       string                 `json:"body"`
	Headers    map[string]interface{} `json:"headers"`
}

func txHttpTriggerHandler(w http.ResponseWriter, r *http.Request) {
	t := time.Now()
	fmt.Printf("=== [MOIMHA] TX Request received at: %s ===\n", t.Format("2006-01-02 15:04:05"))
	fmt.Println("Method:", r.Method)
	fmt.Println("URL:", r.URL)
	fmt.Println("Host:", r.Host)
	fmt.Println("RemoteAddr:", r.RemoteAddr)

	ua := r.Header.Get("User-Agent")
	fmt.Printf("User-Agent: %s\n", ua)
	invocationId := r.Header.Get("X-Azure-Functions-InvocationId")
	fmt.Printf("InvocationId: %s\n", invocationId)

	queryParams := r.URL.Query()
	if len(queryParams) > 0 {
		fmt.Println("Query parameters:")
		for k, v := range queryParams {
			fmt.Printf("  %s: %v\n", k, v)
		}
	}

	outputs := make(map[string]interface{})

	// Create proper HTTP response structure
	httpResponse := HttpResponse{
		StatusCode: 200,
		Body:       `{"hello":"world","message":"Software version: GREEN","timestamp":"` + t.Format("2006-01-02 15:04:05") + `"}`,
		Headers: map[string]interface{}{
			"Content-Type": "application/json",
		},
	}

	outputs["res"] = httpResponse

	response := InvokeResponse{
		Outputs:     outputs,
		Logs:        nil,
		ReturnValue: nil,
	}

	// Set response headers
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Failed to write output: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	fmt.Printf("Response sent successfully at: %s\n", t.Format("2006-01-02 15:04:05"))
}

func main() {
	customHandlerPort, exists := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT")
	if !exists {
		customHandlerPort = "8080" // Default port for local development
		fmt.Println("FUNCTIONS_CUSTOMHANDLER_PORT not set, using default: 8080")
	} else {
		fmt.Println("FUNCTIONS_CUSTOMHANDLER_PORT: " + customHandlerPort)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/transaction", txHttpTriggerHandler)

	fmt.Printf("Go server starting on port %s...\n", customHandlerPort)
	log.Fatal(http.ListenAndServe(":"+customHandlerPort, mux))
}
