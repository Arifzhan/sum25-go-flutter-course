package chatcore

import (
	"context"
	"errors"
	"sync"
)

// Message represents a chat message
type Message struct {
	Sender    string
	Recipient string
	Content   string
	Broadcast bool
	Timestamp int64
}

// Broker handles message routing between users
type Broker struct {
	ctx        context.Context
	input      chan Message
	users      map[string]chan Message
	usersMutex sync.RWMutex
	done       chan struct{}
}

// NewBroker creates a new message broker
func NewBroker(ctx context.Context) *Broker {
	return &Broker{
		ctx:   ctx,
		input: make(chan Message, 100),
		users: make(map[string]chan Message),
		done:  make(chan struct{}),
	}
}

// Run starts the broker event loop
func (b *Broker) Run() {
	go func() {
		for {
			select {
			case <-b.ctx.Done():
				close(b.done)
				return
			case msg := <-b.input:
				if msg.Broadcast {
					b.broadcastMessage(msg)
				} else {
					b.sendPrivateMessage(msg)
				}
			}
		}
	}()
}

// SendMessage sends a message into the broker input queue
func (b *Broker) SendMessage(msg Message) error {
	select {
	case <-b.ctx.Done():
		return errors.New("broker is shut down")
	case b.input <- msg:
		return nil
	}
}

// RegisterUser adds a user to the broker
func (b *Broker) RegisterUser(userID string, recv chan Message) {
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	b.users[userID] = recv
}

// UnregisterUser removes a user from the broker
func (b *Broker) UnregisterUser(userID string) {
	b.usersMutex.Lock()
	defer b.usersMutex.Unlock()
	delete(b.users, userID)
}

// sendPrivateMessage sends a message to a specific recipient
func (b *Broker) sendPrivateMessage(msg Message) {
	b.usersMutex.RLock()
	defer b.usersMutex.RUnlock()
	if ch, ok := b.users[msg.Recipient]; ok {
		select {
		case ch <- msg:
		default:
			// Optional: handle full channel
		}
	}
}

// broadcastMessage sends a message to all users (including sender)
func (b *Broker) broadcastMessage(msg Message) {
	b.usersMutex.RLock()
	defer b.usersMutex.RUnlock()
	for _, ch := range b.users {
		select {
		case ch <- msg:
		default:
			// Optional: handle full channel
		}
	}
}
