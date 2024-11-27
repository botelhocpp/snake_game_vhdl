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
  TYPE t_SnakePart IS RECORD
    X : INTEGER RANGE 0 TO c_GAME_WIDTH - 1;
    Y : INTEGER RANGE 0 TO c_GAME_HEIGHT - 1;
  END RECORD;

  TYPE t_SnakeArray IS ARRAY(0 TO c_MAX_SNAKE_SIZE) OF t_SnakePart;

  SIGNAL r_Snake : t_SnakeArray := (
    OTHERS => (c_GAME_WIDTH/2 - 1, c_GAME_HEIGHT/2 - 1)
  );
  SIGNAL r_Snake_Size : INTEGER RANGE 0 TO c_MAX_SNAKE_SIZE := c_MIN_SNAKE_SIZE;

  SIGNAL r_Video_Enable_Aligned : STD_LOGIC := '0';
  SIGNAL r_H_Sync_Aligned : STD_LOGIC := '1';
  SIGNAL r_V_Sync_Aligned : STD_LOGIC := '1';

  SIGNAL r_Pressed_Up : STD_LOGIC := '0';
  SIGNAL r_Pressed_Down : STD_LOGIC := '0';
  SIGNAL r_Pressed_Left : STD_LOGIC := '0';
  SIGNAL r_Pressed_Right : STD_LOGIC := '0';

  SIGNAL r_X_Pos : INTEGER RANGE 0 TO c_GAME_WIDTH - 1 := c_GAME_WIDTH/2 - 1;
  SIGNAL r_Y_Pos : INTEGER RANGE 0 TO c_GAME_HEIGHT - 1 := c_GAME_HEIGHT/2 - 1;

  SIGNAL w_One_Key_Pressed : STD_LOGIC := '0';
  
  SIGNAL w_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
  SIGNAL w_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
BEGIN 
  w_One_Key_Pressed <= i_Pressed_Up XOR i_Pressed_Down XOR i_Pressed_Left XOR i_Pressed_Right;
  w_H_Pos <= i_H_Pos/c_GAME_SCALE;
  w_V_Pos <= i_V_Pos/c_GAME_SCALE;

  p_SETUP_DIRECTION:
  PROCESS(i_Clk)
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      IF(w_One_Key_Pressed = '1') THEN
        r_Pressed_Up <= i_Pressed_Up;
        r_Pressed_Down <= i_Pressed_Down;
        r_Pressed_Left <= i_Pressed_Left;
        r_Pressed_Right <= i_Pressed_Right;
      END IF;
    END IF;
  END PROCESS p_SETUP_DIRECTION;

  p_UPDATE_POSITION:
  PROCESS(i_Clk)
    VARIABLE v_Counter : INTEGER RANGE 0 TO c_REFRESH_RATE := 0;
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      v_Counter := v_Counter + 1;
      IF(v_Counter = c_REFRESH_RATE) THEN
        v_Counter := 0;
        IF(r_Pressed_Up = '1' AND r_Y_Pos > 0) THEN
          r_Y_Pos <= r_Y_Pos - 1;
        ELSIF(r_Pressed_Down = '1' AND r_Y_Pos < c_GAME_HEIGHT - 1) THEN
          r_Y_Pos <= r_Y_Pos + 1;
        ELSIF(r_Pressed_Left = '1' AND r_X_Pos > 0) THEN
          r_X_Pos <= r_X_Pos - 1;
        ELSIF(r_Pressed_Right = '1' AND r_X_Pos < c_GAME_WIDTH - 1) THEN
          r_X_Pos <= r_X_Pos + 1;
        END IF;

        r_Snake(0).X <= r_X_Pos;
        r_Snake(0).Y <= r_Y_Pos;
        FOR i IN 1 TO c_MAX_SNAKE_SIZE - 1 LOOP
          r_Snake(i).X <= r_Snake(i - 1).X;
          r_Snake(i).Y <= r_Snake(i - 1).Y;
        END LOOP;

      END IF;
    END IF;
  END PROCESS p_UPDATE_POSITION;

  p_DRAW_SNAKE:
  PROCESS(i_Clk)
    VARIABLE v_Render : STD_LOGIC := '0';
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
    v_Render := '0';
    FOR i IN 0 TO c_MAX_SNAKE_SIZE - 1 LOOP
      IF(i < r_Snake_Size AND w_H_Pos = r_Snake(i).X AND w_V_Pos = r_Snake(i).Y) THEN
        v_Render := '1';
      END IF;
    END LOOP;
    
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
  END PROCESS p_DRAW_SNAKE;

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
