variable "packet_token" {
    type = string
}

variable "packet_ssh_key" {
    type = string
}

variable "github_user" {
    default = "kdrag0n"
}

variable "github_token" {
    type = string
}

variable "github_build_repo" {
    default = "kdrag0n/proton-clang-build"
}

variable "github_release_repo" {
    default = "kdrag0n/proton-clang"
}

variable "github_run_id" {
    default = ""
}

variable "git_author_name" {
    type = string
}

variable "git_author_email" {
    type = string
}

variable "telegram_chat_id" {
    default = ""
}

variable "telegram_token" {
    default = ""
}

variable "project_id" {
    default = "f4d3fade-a524-4536-8fe8-a710fbba9929"
}

variable "hostname" {
    default = "proton-clang-builder-01"
}
