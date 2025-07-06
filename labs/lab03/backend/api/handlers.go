package api

import (
	"encoding/json"
	"fmt"
	"lab03-backend/models"
	"lab03-backend/storage"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

type Handler struct {
	storage *storage.MemoryStorage
}

func NewHandler(storage *storage.MemoryStorage) *Handler {
	return &Handler{storage: storage}
}

func (h *Handler) SetupRoutes() *mux.Router {
	router := mux.NewRouter()
	router.Use(corsMiddleware)

	api := router.PathPrefix("/api").Subrouter()
	api.HandleFunc("/messages", h.GetMessages).Methods("GET")
	api.HandleFunc("/messages", h.CreateMessage).Methods("POST")
	api.HandleFunc("/messages/{id}", h.UpdateMessage).Methods("PUT")
	api.HandleFunc("/messages/{id}", h.DeleteMessage).Methods("DELETE")
	api.HandleFunc("/status/{code}", h.GetHTTPStatus).Methods("GET")
	api.HandleFunc("/health", h.HealthCheck).Methods("GET")

	return router
}

func (h *Handler) GetMessages(w http.ResponseWriter, r *http.Request) {
	messages := h.storage.GetAll()
	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    messages,
	})
}

func (h *Handler) CreateMessage(w http.ResponseWriter, r *http.Request) {
	var req models.CreateMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if err := req.Validate(); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	msg, err := h.storage.Create(req.Username, req.Content)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to create message")
		return
	}

	writeJSON(w, http.StatusCreated, models.APIResponse{
		Success: true,
		Data:    msg,
	})
}

func (h *Handler) UpdateMessage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid message ID")
		return
	}

	var req models.UpdateMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if err := req.Validate(); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	msg, err := h.storage.Update(id, req.Content)
	if err != nil {
		writeError(w, http.StatusNotFound, "Message not found")
		return
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    msg,
	})
}

func (h *Handler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid message ID")
		return
	}

	if err := h.storage.Delete(id); err != nil {
		writeError(w, http.StatusNotFound, "Message not found")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetHTTPStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	code, err := strconv.Atoi(vars["code"])
	if err != nil || code < 100 || code > 599 {
		writeError(w, http.StatusBadRequest, "Invalid HTTP status code")
		return
	}

	imageURL := fmt.Sprintf("http://%s/api/cat/%d", r.Host, code)
	response := models.HTTPStatusResponse{
		StatusCode:  code,
		ImageURL:    imageURL,
		Description: getHTTPStatusDescription(code),
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    response,
	})
}

func (h *Handler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":         "healthy",
		"version":        "1.0.0",
		"total_messages": h.storage.Count(),
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    response,
	})
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, models.APIResponse{
		Success: false,
		Error:   message,
	})
}

func getHTTPStatusDescription(code int) string {
	descriptions := map[int]string{
		100: "Continue",
		200: "OK",
		201: "Created",
		400: "Bad Request",
		404: "Not Found",
		500: "Internal Server Error",
		418: "I'm a teapot",
		503: "Service Unavailable",
	}

	if desc, ok := descriptions[code]; ok {
		return desc
	}
	return "Unknown Status"
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Max-Age", "86400")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
