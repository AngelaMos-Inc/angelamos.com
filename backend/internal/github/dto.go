// AngelaMos | 2026
// dto.go

package github

import "time"

type Repo struct {
	Stars     int       `json:"stars"`
	Forks     int       `json:"forks"`
	Available bool      `json:"available"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type repoResponse struct {
	StargazersCount int `json:"stargazers_count"`
	ForksCount      int `json:"forks_count"`
}
