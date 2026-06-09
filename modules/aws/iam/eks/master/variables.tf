variable "cluster-name" {
    type = string 
    description = "Name of the cluster"
    
}

variable "tags" {
    type = map {string}
    description = "The tag name for all resources"
    default = {}
} 