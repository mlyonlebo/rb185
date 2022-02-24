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
      list_id = tuple["id"].to_i
      todos = format_todos(list_id)
      {id: list_id, name: tuple["name"], todos: todos}
    end
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = "SELECT * FROM lists"
    result = query(sql)

    format_lists(result)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
    
    format_lists(result).first
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
    # @session[:lists].reject! { |list| list[:id] == id }
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
    # list = find_list(list_id)
    # list[:todos].reject! { |todo| todo[:id] == todo_id }
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