package realtime

import (
	"encoding/json"
	"time"

	"github.com/gorilla/websocket"
	"github.com/tareeqmajdapp/backend/internal/logger"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 30 * time.Second
	pingPeriod     = (pongWait * 8) / 10
	maxMessageSize = 4096
	sendBuffer     = 32
)

type Client struct {
	hub        *Hub
	conn       *websocket.Conn
	send       chan []byte
	registered chan struct{}
	userID     string
	userName   string
	section    string
	role       string
	monitor    bool
}

func NewClient(hub *Hub, conn *websocket.Conn, userID, userName, section, role string, monitor bool) *Client {
	return &Client{
		hub:        hub,
		conn:       conn,
		send:       make(chan []byte, sendBuffer),
		registered: make(chan struct{}),
		userID:     userID,
		userName:   userName,
		section:    section,
		role:       role,
		monitor:    monitor,
	}
}

func (c *Client) Run() {
	c.hub.register <- c
	<-c.registered
	go c.writePump()
	c.readPump()
}

func (c *Client) enqueue(payload []byte) bool {
	select {
	case c.send <- payload:
		return true
	default:
		return false
	}
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		return c.conn.SetReadDeadline(time.Now().Add(pongWait))
	})

	for {
		_, payload, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway,
				websocket.CloseNormalClosure,
				websocket.CloseAbnormalClosure) {
				logger.Warn("realtime: read error for user %s: %v", c.userID, err)
			}
			return
		}

		var msg InboundMessage
		if err := json.Unmarshal(payload, &msg); err != nil {
			continue
		}

		switch msg.Type {
		case MsgProgress, MsgStopped, MsgHeartbeat:
			c.hub.inbound <- clientMessage{client: c, message: msg}
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case payload, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, payload); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
