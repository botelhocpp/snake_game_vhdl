LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.GamePkg.ALL;
USE WORK.HdmiPkg.ALL;
 
ENTITY SnakeGame IS
PORT (
    i_Clk : IN STD_LOGIC;
    i_Video_Enable : IN STD_LOGIC;
    i_H_Sync : IN STD_LOGIC;
    i_V_Sync : IN STD_LOGIC;
    i_Pressed_Up : IN STD_LOGIC;
    i_Pressed_Down : IN STD_LOGIC;
    i_Pressed_Left : IN STD_LOGIC;
    i_Pressed_Right : IN STD_LOGIC;
    i_Pressed_A : IN STD_LOGIC;
    i_Pressed_B : IN STD_LOGIC;
    i_H_Pos : IN INTEGER RANGE 0 TO c_H_MAX;
    i_V_Pos : IN INTEGER RANGE 0 TO c_V_MAX;
    o_Video_Enable : OUT STD_LOGIC;
    o_H_Sync : OUT STD_LOGIC;
    o_V_Sync : OUT STD_LOGIC;
    o_Channel_R : OUT t_Byte;
    o_Channel_G : OUT t_Byte;
    o_Channel_B : OUT t_Byte
);
END ENTITY;
 
ARCHITECTURE RTL OF SnakeGame IS
  TYPE t_GameState IS (
    s_IDLE,
    s_RUNNING
  );
  
  SIGNAL r_State : t_GameState := s_IDLE;

  TYPE t_SnakePart IS RECORD
    X : INTEGER RANGE 0 TO c_GAME_WIDTH - 1;
    Y : INTEGER RANGE 0 TO c_GAME_HEIGHT - 1;
  END RECORD;

  TYPE t_SnakeArray IS ARRAY(0 TO c_MAX_SNAKE_SIZE) OF t_SnakePart;

  SIGNAL r_Snake : t_SnakeArray := (
    OTHERS => (c_GAME_X_MIDDLE, c_GAME_Y_MIDDLE)
  );
  SIGNAL r_Snake_Size : INTEGER RANGE 0 TO c_MAX_SNAKE_SIZE := c_MIN_SNAKE_SIZE;

  SIGNAL r_Video_Enable_Aligned : STD_LOGIC := '0';
  SIGNAL r_H_Sync_Aligned : STD_LOGIC := '1';
  SIGNAL r_V_Sync_Aligned : STD_LOGIC := '1';

  SIGNAL r_Pressed_Up : STD_LOGIC := '0';
  SIGNAL r_Pressed_Down : STD_LOGIC := '0';
  SIGNAL r_Pressed_Left : STD_LOGIC := '0';
  SIGNAL r_Pressed_Right : STD_LOGIC := '0';

  ALIAS a_Head_X_Pos IS r_Snake(0).X;
  ALIAS a_Head_Y_Pos IS r_Snake(0).Y;

  SIGNAL w_One_Key_Pressed : STD_LOGIC := '0';
  
  SIGNAL w_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
  SIGNAL w_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
  
  SIGNAL w_Current_Random_X : INTEGER RANGE 0 TO c_GAME_WIDTH - 1 := 0;
  SIGNAL w_Current_Random_Y : INTEGER RANGE 0 TO c_GAME_HEIGHT - 1 := 0;

  SIGNAL r_Food_X : INTEGER RANGE 0 TO c_GAME_WIDTH - 1 := 0;
  SIGNAL r_Food_Y : INTEGER RANGE 0 TO c_GAME_WIDTH - 1 := 0;

  SIGNAL w_Game_Active : STD_LOGIC := '0';
BEGIN 
  w_One_Key_Pressed <= i_Pressed_Up OR i_Pressed_Down OR i_Pressed_Left OR i_Pressed_Right;
  w_Game_Active <= '1' WHEN (r_State = s_RUNNING) ELSE '0'; 
  w_H_Pos <= i_H_Pos/c_GAME_SCALE;
  w_V_Pos <= i_V_Pos/c_GAME_SCALE;

  p_GAME_STATE_MACHINE:
  PROCESS(i_Clk)
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      CASE r_State IS
        WHEN s_IDLE =>
          IF(w_One_Key_Pressed = '1') THEN
            r_Food_X <= w_Current_Random_X;
            r_Food_Y <= w_Current_Random_Y;
            r_State <= s_RUNNING;
          END IF;
          r_Snake_Size <= c_MIN_SNAKE_SIZE;

        WHEN s_RUNNING =>
          -- Collision with wall
          IF(
            (a_Head_Y_Pos = c_GAME_LIMIT_UPPER_LINE) OR 
            (a_Head_Y_Pos = c_GAME_LIMIT_LOWER_LINE) OR
            (a_Head_X_Pos = c_GAME_LIMIT_LEFT_LINE) OR
            (a_Head_X_Pos = c_GAME_LIMIT_RIGHT_LINE)
          ) THEN
            r_State <= s_IDLE;
            
          -- Collision with snake
          ELSIF(r_Snake_Size > c_MIN_SNAKE_SIZE) THEN
            FOR i IN 1 TO c_MAX_SNAKE_SIZE - 1 LOOP
              IF(i < r_Snake_Size AND a_Head_X_Pos = r_Snake(i).X AND a_Head_Y_Pos = r_Snake(i).Y) THEN
                  r_State <= s_IDLE; 
              END IF;
            END LOOP;
          END IF;
            
          -- Collision with food
          IF(
              a_Head_X_Pos = r_Food_X AND 
              a_Head_Y_Pos = r_Food_Y
            ) THEN
            r_Snake_Size <= r_Snake_Size + 1;

            r_Food_X <= w_Current_Random_X;
            r_Food_Y <= w_Current_Random_Y;
          END IF;
      END CASE;
    END IF;
  END PROCESS;

  p_SETUP_DIRECTION:
  PROCESS(i_Clk)
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      IF(r_State = s_IDLE) THEN
        r_Pressed_Up <= '0';
        r_Pressed_Down <= '0';
        r_Pressed_Left <= '0';
        r_Pressed_Right <= '0';
      ELSIF(
        (w_One_Key_Pressed = '1') AND
        NOT (r_Pressed_Up = '1' AND i_Pressed_Down = '1') AND
        NOT (r_Pressed_Down = '1' AND i_Pressed_Up = '1') AND
        NOT (r_Pressed_Left = '1' AND i_Pressed_Right = '1') AND
        NOT (r_Pressed_Right = '1' AND i_Pressed_Left = '1')
      ) THEN
        r_Pressed_Up <= i_Pressed_Up;
        r_Pressed_Down <= i_Pressed_Down;
        r_Pressed_Left <= i_Pressed_Left;
        r_Pressed_Right <= i_Pressed_Right;
      END IF;
    END IF;
  END PROCESS p_SETUP_DIRECTION;

  p_UPDATE_SNAKE_POSITION:
  PROCESS(i_Clk)
    VARIABLE v_Counter : INTEGER RANGE 0 TO c_REFRESH_RATE := 0;
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      CASE r_State IS
        WHEN s_IDLE =>
          r_Snake <= (OTHERS => (c_GAME_X_MIDDLE, c_GAME_Y_MIDDLE));
          v_Counter := 0;
  
        WHEN s_RUNNING =>
          v_Counter := v_Counter + 1;
          IF(v_Counter = c_REFRESH_RATE) THEN
            v_Counter := 0;
  
            FOR i IN c_MAX_SNAKE_SIZE - 1 DOWNTO 1 LOOP
              r_Snake(i).X <= r_Snake(i - 1).X;
              r_Snake(i).Y <= r_Snake(i - 1).Y;
            END LOOP;

            IF(r_Pressed_Up = '1' AND a_Head_Y_Pos > c_GAME_LIMIT_UPPER_LINE) THEN
              a_Head_Y_Pos <= a_Head_Y_Pos - 1;
            ELSIF(r_Pressed_Down = '1' AND a_Head_Y_Pos < c_GAME_LIMIT_LOWER_LINE) THEN
              a_Head_Y_Pos <= a_Head_Y_Pos + 1;
            ELSIF(r_Pressed_Left = '1' AND a_Head_X_Pos > c_GAME_LIMIT_LEFT_LINE) THEN
              a_Head_X_Pos <= a_Head_X_Pos - 1;
            ELSIF(r_Pressed_Right = '1' AND a_Head_X_Pos < c_GAME_LIMIT_RIGHT_LINE) THEN
              a_Head_X_Pos <= a_Head_X_Pos + 1;
            END IF;
  
          END IF;
      END CASE;
    END IF;
  END PROCESS p_UPDATE_SNAKE_POSITION;
  

  p_RANDOM_NUMBER_GENERATOR:
  PROCESS(i_Clk)
    VARIABLE v_Random_X : UNSIGNED(10 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_Random_Y : UNSIGNED(10 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_Random_Modifier : INTEGER RANGE 0 TO 100;
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      IF(r_Pressed_Up = '1') THEN
        v_Random_Modifier := 11;
      ELSIF(r_Pressed_Down = '1') THEN
        v_Random_Modifier := 22;
      ELSIF(r_Pressed_Left = '1') THEN
        v_Random_Modifier := 33;
      ELSIF(r_Pressed_Right = '1') THEN
        v_Random_Modifier := 44;
      ELSE
        v_Random_Modifier := 0;
      END IF;

      v_Random_X := v_Random_X + TO_UNSIGNED(i_H_Pos, 11) + TO_UNSIGNED(v_Random_Modifier, 11);
      v_Random_Y := v_Random_Y + TO_UNSIGNED(i_V_Pos, 11) + TO_UNSIGNED(v_Random_Modifier, 11);

      w_Current_Random_X <= c_GAME_FIRST_COL + (TO_INTEGER(v_Random_X) MOD (c_GAME_LAST_COL - c_GAME_FIRST_COL + 1));
      w_Current_Random_Y <= c_GAME_FIRST_ROW + (TO_INTEGER(v_Random_Y) MOD (c_GAME_LAST_ROW - c_GAME_FIRST_ROW + 1));
    END IF;
  END PROCESS p_RANDOM_NUMBER_GENERATOR;

  p_DRAW_GAME:
  PROCESS(i_Clk)
    VARIABLE v_Render : STD_LOGIC := '0';
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      v_Render := '0';
      
      -- Render snake?
      FOR i IN 0 TO c_MAX_SNAKE_SIZE - 1 LOOP
        IF(
          (i < r_Snake_Size AND w_H_Pos = r_Snake(i).X AND w_V_Pos = r_Snake(i).Y) AND
          (i_H_Pos MOD c_GAME_SCALE /= 0) AND (i_H_Pos MOD c_GAME_SCALE /= c_GAME_SCALE - 1) AND
          (i_V_Pos MOD c_GAME_SCALE /= 0) AND (i_V_Pos MOD c_GAME_SCALE /= c_GAME_SCALE - 1)
        ) THEN
          v_Render := '1';
        END IF;
      END LOOP;

      -- Render food?
      IF(w_Game_Active = '1' AND r_Food_X = w_H_Pos AND r_Food_Y = w_V_Pos) THEN
        v_Render := '1';
      END IF;

      -- Render game limits?
      IF(
        (w_V_Pos >= c_GAME_LIMIT_UPPER_LINE AND 
        w_V_Pos <= c_GAME_LIMIT_LOWER_LINE AND 
        w_H_Pos >= c_GAME_LIMIT_LEFT_LINE AND 
        w_H_Pos <= c_GAME_LIMIT_RIGHT_LINE) AND
        
        ((w_H_Pos = c_GAME_LIMIT_LEFT_LINE) OR
        (w_H_Pos = c_GAME_LIMIT_RIGHT_LINE) OR
        (w_V_Pos = c_GAME_LIMIT_UPPER_LINE) OR
        (w_V_Pos = c_GAME_LIMIT_LOWER_LINE))
      ) THEN
        v_Render := '1';
      END IF;
    
      IF(v_Render = '1') THEN
        o_Channel_R <= (OTHERS => '1');
        o_Channel_G <= (OTHERS => '1');
        o_Channel_B <= (OTHERS => '1');
      ELSE
        o_Channel_R <= (OTHERS => '0');
        o_Channel_G <= (OTHERS => '0');
        o_Channel_B <= (OTHERS => '0');
      END IF;
    
    END IF;
  END PROCESS p_DRAW_GAME;

  p_SYNC_PULSES:
  PROCESS(i_Clk)
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      r_Video_Enable_Aligned <= i_Video_Enable;
      r_H_Sync_Aligned <= i_H_Sync;
      r_V_Sync_Aligned <= i_V_Sync;
      
      o_Video_Enable <= r_Video_Enable_Aligned;
      o_H_Sync <= r_H_Sync_Aligned;
      o_V_Sync <= r_V_Sync_Aligned;
    END IF;
  END PROCESS p_SYNC_PULSES;
END ARCHITECTURE;
