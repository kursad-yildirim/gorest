package main

// curl localhost:8080/movies --include --header "Content-Type: application/json" --request "POST" --data '{"id": 4, "title": "Police Academy", "year": "1984", "director": "Hugh Wilson"}'
import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type movie struct {
	ID     int    `json:"ID"`
	Title  string `json:"title"`
	Aired  string `json:"year"`
	Madeby string `json:"director"`
}

var collection = []movie{
	{ID: 1, Title: "The Naked Gun", Aired: "1988", Madeby: "David Zucker"},
	{ID: 2, Title: "Monty Python and the Holy Grail", Aired: "1975", Madeby: "Terry Gilliam & Terry Jones"},
	{ID: 3, Title: "Airplane!", Aired: "1980", Madeby: "Jim Abrahams & David Zucker & Jerry Zucker"},
}

func main() {
	router := gin.Default()

	router.GET("/movies", getMovies)
	router.GET("/movies/:id", getMovieByID)
	router.POST("/movies", addMovie)

	router.Run("10.140.239.254:8080")
}

func getMovies(c *gin.Context) {
	fmt.Println("Client IP:", c.ClientIP())
	c.IndentedJSON(http.StatusOK, collection)
}

func addMovie(c *gin.Context) {
	var newMovie movie

	if err := c.BindJSON(&newMovie); err != nil {
		return
	}

	collection = append(collection, newMovie)
	c.IndentedJSON(http.StatusCreated, newMovie)
}

func getMovieByID(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("id"))

	for _, a := range collection {
		if a.ID == id {
			c.IndentedJSON(http.StatusOK, a)
			return
		}
	}
	c.IndentedJSON(http.StatusNotFound, gin.H{"message": "movie not found"})
}
