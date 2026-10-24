// AngelaMos | 2026
// dto.go

package social

import "time"

type Stats struct {
	Followers  int       `json:"followers"`
	Media      int       `json:"media"`
	Configured bool      `json:"configured"`
	UpdatedAt  time.Time `json:"updatedAt"`
}

type igResponse struct {
	FollowersCount int `json:"followers_count"`
	MediaCount     int `json:"media_count"`
}
