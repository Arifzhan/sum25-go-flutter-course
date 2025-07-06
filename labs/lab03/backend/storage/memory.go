package storage

import (
	"errors"
	"lab03-backend/models"
	"sync"
)

type MemoryStorage struct {
	mu       sync.RWMutex
	messages map[int]*models.Message
	nextID   int
}

func NewMemoryStorage() *MemoryStorage {
	return &MemoryStorage{
		mu:       sync.RWMutex{},
		messages: make(map[int]*models.Message),
		nextID:   1,
	}
}

func (ms *MemoryStorage) Create(username, content string) (*models.Message, error) {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	msg := models.NewMessage(ms.nextID, username, content)
	ms.messages[ms.nextID] = msg
	ms.nextID++
	return msg, nil
}

func (ms *MemoryStorage) GetByID(id int) (*models.Message, error) {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	if msg, exists := ms.messages[id]; exists {
		return msg, nil
	}
	return nil, errors.New("message not found")
}

func (ms *MemoryStorage) GetAll() []*models.Message {
	ms.mu.RLock()
	defer ms.mu.RUnlock()

	messages := make([]*models.Message, 0, len(ms.messages))
	for _, msg := range ms.messages {
		messages = append(messages, msg)
	}
	return messages
}

func (ms *MemoryStorage) Update(id int, content string) (*models.Message, error) {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	if msg, exists := ms.messages[id]; exists {
		msg.Content = content
		return msg, nil
	}
	return nil, errors.New("message not found")
}

func (ms *MemoryStorage) Delete(id int) error {
	ms.mu.Lock()
	defer ms.mu.Unlock()

	if _, exists := ms.messages[id]; !exists {
		return errors.New("message not found")
	}
	delete(ms.messages, id)
	return nil
}

func (ms *MemoryStorage) Count() int {
	ms.mu.RLock()
	defer ms.mu.RUnlock()
	return len(ms.messages)
}
