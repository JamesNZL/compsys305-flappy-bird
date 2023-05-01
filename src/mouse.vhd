-----
--Pong game 2018
-----
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity MOUSE is
    port (
        clock_25Mhz, reset : in std_logic;
        mouse_data : inout std_logic;
        mouse_clk : inout std_logic;
        left_button, right_button : out std_logic;
        mouse_cursor_row : out signed(9 downto 0);
        mouse_cursor_column : out signed(9 downto 0));
end MOUSE;

architecture behavior of MOUSE is

    type STATE_TYPE is (INHIBIT_TRANS, LOAD_COMMAND, LOAD_COMMAND2, WAIT_OUTPUT_READY,
        WAIT_CMD_ACK, INPUT_PACKETS);
    -- Signals for Mouse
    signal mouse_state : state_type;
    signal inhibit_wait_count : std_logic_vector(11 downto 0);
    signal CHARIN, CHAROUT : std_logic_vector(7 downto 0);
    signal new_cursor_row, new_cursor_column : std_logic_vector(9 downto 0);
    signal cursor_row, cursor_column : std_logic_vector(9 downto 0);
    signal INCNT, OUTCNT, mSB_OUT : std_logic_vector(3 downto 0);
    signal PACKET_COUNT : std_logic_vector(1 downto 0);
    signal SHIFTIN : std_logic_vector(8 downto 0);
    signal SHIFTOUT : std_logic_vector(10 downto 0);
    signal PACKET_CHAR1, PACKET_CHAR2,
    PACKET_CHAR3 : std_logic_vector(7 downto 0);
    signal MOUSE_CLK_BUF, DATA_READY, READ_CHAR : std_logic;
    signal i : integer;
    signal cursor, iready_set, break, toggle_next,
    output_ready, send_char, send_data : std_logic;
    signal MOUSE_DATA_DIR, MOUSE_DATA_OUT, MOUSE_DATA_BUF,
    MOUSE_CLK_DIR : std_logic;
    signal MOUSE_CLK_FILTER : std_logic;
    signal filter : std_logic_vector(7 downto 0);

begin

    mouse_cursor_row <= signed(cursor_row);
    mouse_cursor_column <= signed(cursor_column);

    -- tri_state control logic for mouse data and clock lines
    MOUSE_DATA <= 'Z' when MOUSE_DATA_DIR = '0' else
                  MOUSE_DATA_BUF;
    MOUSE_CLK <= 'Z' when MOUSE_CLK_DIR = '0' else
                 MOUSE_CLK_BUF;
    -- state machine to send init command and start recv process.
    process (reset, clock_25Mhz)
    begin
        if reset = '1' then
            mouse_state <= INHIBIT_TRANS;
            inhibit_wait_count <= conv_std_logic_vector(0, 12);
            SEND_DATA <= '0';
        elsif clock_25Mhz'EVENT and clock_25Mhz = '1' then
            case mouse_state is
                    -- Mouse powers up and sends self test codes, AA and 00 out before board is downloaded
                    -- Pull clock line low to inhibit any transmissions from mouse
                    -- Need at least 60usec to stop a transmission in progress
                    -- Note: This is perhaps optional since mouse should not be tranmitting
                when INHIBIT_TRANS =>
                    inhibit_wait_count <= inhibit_wait_count + 1;
                    if inhibit_wait_count(11 downto 10) = "11" then
                        mouse_state <= LOAD_COMMAND;
                    end if;
                    -- Enable Streaming Mode Command, F4
                    charout <= "11110100";
                    -- Pull data low to signal data available to mouse
                when LOAD_COMMAND =>
                    SEND_DATA <= '1';
                    mouse_state <= LOAD_COMMAND2;
                when LOAD_COMMAND2 =>
                    SEND_DATA <= '1';
                    mouse_state <= WAIT_OUTPUT_READY;
                    -- Wait for Mouse to Clock out all bits in command.
                    -- Command sent is F4, Enable Streaming Mode
                    -- This tells the mouse to start sending 3-byte packets with movement data
                when WAIT_OUTPUT_READY =>
                    SEND_DATA <= '0';
                    -- Output Ready signals that all data is clocked out of shift register
                    if OUTPUT_READY = '1' then
                        mouse_state <= WAIT_CMD_ACK;
                    else
                        mouse_state <= WAIT_OUTPUT_READY;
                    end if;
                    -- Wait for Mouse to send back Command Acknowledge, FA
                when WAIT_CMD_ACK =>
                    SEND_DATA <= '0';
                    if IREADY_SET = '1' then
                        mouse_state <= INPUT_PACKETS;
                    end if;
                    -- Release clock_25Mhz and data lines and go into mouse input mode
                    -- Stay in this state and recieve 3-byte mouse data packets forever
                    -- Default rate is 100 packets per second
                when INPUT_PACKETS =>
                    mouse_state <= INPUT_PACKETS;
            end case;
        end if;
    end process;

    with mouse_state select
        -- Mouse Data Tri-state control line: '1' DE0 drives, '0'=Mouse Drives
        MOUSE_DATA_DIR <= '0' when INHIBIT_TRANS,
        '0' when LOAD_COMMAND,
        '0' when LOAD_COMMAND2,
        '1' when WAIT_OUTPUT_READY,
        '0' when WAIT_CMD_ACK,
        '0' when INPUT_PACKETS;
    -- Mouse Clock Tri-state control line: '1' DE0 drives, '0'=Mouse Drives
    with mouse_state select
        MOUSE_CLK_DIR <= '1' when INHIBIT_TRANS,
        '1' when LOAD_COMMAND,
        '1' when LOAD_COMMAND2,
        '0' when WAIT_OUTPUT_READY,
        '0' when WAIT_CMD_ACK,
        '0' when INPUT_PACKETS;
    with mouse_state select
        -- Input to DE0 tri-state buffer mouse clock_25Mhz line
        MOUSE_CLK_BUF <= '0' when INHIBIT_TRANS,
        '1' when LOAD_COMMAND,
        '1' when LOAD_COMMAND2,
        '1' when WAIT_OUTPUT_READY,
        '1' when WAIT_CMD_ACK,
        '1' when INPUT_PACKETS;

    -- filter for mouse clock
    process
    begin
        wait until clock_25Mhz'event and clock_25Mhz = '1';
        filter(7 downto 1) <= filter(6 downto 0);
        filter(0) <= MOUSE_CLK;
        if filter = "11111111" then
            MOUSE_CLK_FILTER <= '1';
        elsif filter = "00000000" then
            MOUSE_CLK_FILTER <= '0';
        end if;
    end process;

    --This process sends serial data going to the mouse
    SEND_UART : process (send_data, Mouse_clK_filter)
    begin
        if SEND_DATA = '1' then
            OUTCNT <= "0000";
            SEND_CHAR <= '1';
            OUTPUT_READY <= '0';
            -- Send out Start Bit(0) + Command(F4) + Parity  Bit(0) + Stop Bit(1)
            SHIFTOUT(8 downto 1) <= CHAROUT;
            -- START BIT
            SHIFTOUT(0) <= '0';
            -- COMPUTE ODD PARITY BIT
            SHIFTOUT(9) <= not (charout(7) xor charout(6) xor charout(5) xor
                           charout(4) xor Charout(3) xor charout(2) xor charout(1) xor
                           charout(0));
            -- STOP BIT 
            SHIFTOUT(10) <= '1';
            -- Data Available Flag to Mouse
            -- Tells mouse to clock out command data (is also start bit)
            MOUSE_DATA_BUF <= '0';

        elsif (MOUSE_CLK_filter'event and MOUSE_CLK_filter = '0') then
            if MOUSE_DATA_DIR = '1' then
                -- SHIFT OUT NEXT SERIAL BIT
                if SEND_CHAR = '1' then
                    -- Loop through all bits in shift register
                    if OUTCNT <= "1001" then
                        OUTCNT <= OUTCNT + 1;
                        -- Shift out next bit to mouse
                        SHIFTOUT(9 downto 0) <= SHIFTOUT(10 downto 1);
                        SHIFTOUT(10) <= '1';
                        MOUSE_DATA_BUF <= SHIFTOUT(1);
                        OUTPUT_READY <= '0';
                        -- END OF CHARACTER
                    else
                        SEND_CHAR <= '0';
                        -- Signal the character has been output
                        OUTPUT_READY <= '1';
                        OUTCNT <= "0000";
                    end if;
                end if;
            end if;
        end if;
    end process SEND_UART;

    RECV_UART : process (reset, mouse_clk_filter)
    begin
        if RESET = '1' then
            INCNT <= "0000";
            READ_CHAR <= '0';
            PACKET_COUNT <= "00";
            LEFT_BUTTON <= '0';
            RIGHT_BUTTON <= '0';
            CHARIN <= "00000000";
        elsif MOUSE_CLK_FILTER'event and MOUSE_CLK_FILTER = '0' then
            if MOUSE_DATA_DIR = '0' then
                if MOUSE_DATA = '0' and READ_CHAR = '0' then
                    READ_CHAR <= '1';
                    IREADY_SET <= '0';
                else
                    -- SHIFT IN NEXT SERIAL BIT
                    if READ_CHAR = '1' then
                        if INCNT < "1001" then
                            INCNT <= INCNT + 1;
                            SHIFTIN(7 downto 0) <= SHIFTIN(8 downto 1);
                            SHIFTIN(8) <= MOUSE_DATA;
                            IREADY_SET <= '0';
                            -- END OF CHARACTER
                        else
                            CHARIN <= SHIFTIN(7 downto 0);
                            READ_CHAR <= '0';
                            IREADY_SET <= '1';
                            PACKET_COUNT <= PACKET_COUNT + 1;
                            -- PACKET_COUNT = "00" IS ACK COMMAND
                            if PACKET_COUNT = "00" then
                                -- Set Cursor to middle of screen
                                cursor_column <= CONV_STD_LOGIC_VECTOR(320, 10);
                                cursor_row <= CONV_STD_LOGIC_VECTOR(240, 10);
                                NEW_cursor_column <= CONV_STD_LOGIC_VECTOR(320, 10);
                                NEW_cursor_row <= CONV_STD_LOGIC_VECTOR(240, 10);
                            elsif PACKET_COUNT = "01" then
                                PACKET_CHAR1 <= SHIFTIN(7 downto 0);
                                -- Limit Cursor on Screen Edges. Check for left screen limit
                                -- All numbers are positive only, and need to check for zero wrap around.
                                -- Set limits higher since mouse can move up to 128 pixels in one packet
                                if (cursor_row < 128) and ((NEW_cursor_row > 256) or
                                    (NEW_cursor_row < 2)) then
                                    cursor_row <= CONV_STD_LOGIC_VECTOR(0, 10);
                                    -- Check for right screen limit
                                elsif NEW_cursor_row > 480 then
                                    cursor_row <= CONV_STD_LOGIC_VECTOR(480, 10);
                                else
                                    cursor_row <= NEW_cursor_row;
                                end if;
                                -- Check for top screen limit
                                if (cursor_column < 128) and ((NEW_cursor_column > 256) or
                                    (NEW_cursor_column < 2)) then
                                    cursor_column <= CONV_STD_LOGIC_VECTOR(0, 10);
                                    -- Check for bottom screen limit
                                elsif NEW_cursor_column > 640 then
                                    cursor_column <= CONV_STD_LOGIC_VECTOR(640, 10);
                                else
                                    cursor_column <= NEW_cursor_column;
                                end if;
                            elsif PACKET_COUNT = "10" then
                                PACKET_CHAR2 <= SHIFTIN(7 downto 0);
                            elsif PACKET_COUNT = "11" then
                                PACKET_CHAR3 <= SHIFTIN(7 downto 0);
                            end if;
                            INCNT <= conv_std_logic_vector(0, 4);
                            if PACKET_COUNT = "11" then
                                PACKET_COUNT <= "01";
                                -- Packet Complete, so process data in packet
                                -- Sign extend X AND Y two's complement motion values and 
                                -- add to Current Cursor Address
                                -- Y Motion is Negative since up is a lower row address
                                NEW_cursor_row <= cursor_row - (PACKET_CHAR3(7) &
                                                  PACKET_CHAR3(7) & PACKET_CHAR3);
                                NEW_cursor_column <= cursor_column + (PACKET_CHAR2(7) &
                                                     PACKET_CHAR2(7) & PACKET_CHAR2);
                                LEFT_BUTTON <= PACKET_CHAR1(0);
                                RIGHT_BUTTON <= PACKET_CHAR1(1);
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process RECV_UART;

end behavior;