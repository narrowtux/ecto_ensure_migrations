CREATE CAST (integer AS jsonb) WITH FUNCTION to_jsonb(integer);

CREATE FUNCTION split_string(source text, delimiter text) 
RETURNS ARRAY(string) 
LANGUAGE 'plpgsql'
AS $$
BEGIN
  RETURN ARRAY[]
END
$$;

