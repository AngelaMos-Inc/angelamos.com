// AngelaMos | 2026
// dto.go

package contact

type SubmitRequest struct {
	Name    string `json:"name"    validate:"required,min=1,max=120"`
	ReplyTo string `json:"replyTo" validate:"required,min=1,max=200"`
	Message string `json:"message" validate:"required,min=1,max=5000"`
}

type SubmitResponse struct {
	Status string `json:"status"`
}
