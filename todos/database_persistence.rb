require "pg"

class DatabasePersistence

  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def fetch_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    query(sql, list_id)
  end

  def format_lists(result)
    result.map do |tuple|
      { id: tuple["id"].to_i, 
        name: tuple["name"],
        todos_count: tuple["todos_count"].to_i,
        todos_remaining_count: tuple["todos_remaining_count"].to_i }
    end
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = <<~SQL 
      SELECT lists.*, 
      COUNT(todos.id) AS todos_count,
      COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
      FROM lists 
      LEFT OUTER JOIN todos
      ON lists.id = todos.list_id
      GROUP BY lists.id
      ORDER BY lists.name;
    SQL
    
    result = query(sql)

    format_lists(result)
  end

  def find_list(id)
    sql = <<~SQL 
      SELECT lists.*, 
      COUNT(todos.id) AS todos_count,
      COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count
      FROM lists 
      LEFT OUTER JOIN todos
      ON lists.id = todos.list_id
      WHERE lists.id = $1
      GROUP BY lists.id
      ORDER BY lists.name;
    SQL

    result = query(sql, id)
    tuple = result.first
    
    list_id = tuple[:id].to_i
    todos = fetch_todos(list_id)

    { id: tuple["id"].to_i, 
      name: tuple["name"],
      todos: todos,
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i }
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def delete_list(id)
    sql = "DELETE FROM todos WHERE list_id = $1;"
    query(sql, id)
    sql = "DELETE FROM lists WHERE id = $1;"
    query(sql, id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2;"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(sql, new_status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  private

  def format_todos(list_id)
    result = fetch_todos(list_id)

    result.map do |tuple|
      { id: tuple["id"].to_i, 
        name: tuple["name"], 
        completed: tuple["completed"] == 't', 
        list_id: tuple["list_id"].to_i }
    end
  end
end