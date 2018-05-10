-- Postgres SQL to create DB Tables --
CREATE USER spark WITH PASSWORD 'spark';
CREATE DATABASE xys OWNER spark;

CREATE TABLE ADMIN(
    id	SERIAL PRIMARY KEY  NOT NULL,
    username VARCHAR(40) NOT NULL UNIQUE,
    password VARCHAR(40) NOT NULL,
    is_super BOOLEAN NOT NULL DEFAULT false
);


CREATE TABLE USERGROUPS(
 id SERIAL PRIMARY KEY NOT NULL,
 group_name varchar(20),
 description TEXT, 
 created_on TIMESTAMP default current_timestamp
);


CREATE TABLE ADMIN_USERGROUPS(
 id SERIAL PRIMARY KEY NOT NULL,
 admin_id INT NOT NULL references ADMIN(id),
 group_id INT NOT NULL references USERGROUPS(id),
 created_on TIMESTAMP default current_timestamp 
);

ALTER TABLE ADMIN_USERGROUPS ADD CONSTRAINT ADMIN_USERGROUPS_UNIQUEKEY UNIQUE (admin_id,group_id);



CREATE TABLE EVENT(
   id    SERIAL PRIMARY KEY NOT NULL,
   name   CHAR(50) NOT NULL,
   created_on  TIMESTAMP default current_timestamp,
   description Text NOT NULL default '',
   is_active BOOLEAN NOT NULL default true,
   access_code Text,
   owner_group INT not null references usergroups(id)
);


-- Table to store Tag information
CREATE TABLE TAG(
   id    SERIAL PRIMARY KEY      NOT NULL,
   name   CHAR(50) NOT NULL,
   created_on  TIMESTAMP default current_timestamp,
   description Text NOT NULL default '',
   event_id BIGINT NOT NULL references Event(id)

);

-- Table to update Sentiment Aggregate --
CREATE TABLE SENTIMENT_AGG(
   id    SERIAL PRIMARY KEY      NOT NULL,
   tag_id BIGINT   NOT NULL references TAG(id),
   upset_agg  INT default 0,
   sad_agg   INT default 0,
   neutral_agg INT default 0,
   happy_agg INT default 0,
   glad_agg INT default 0,
   updated_on     TIMESTAMP default current_timestamp
);


-- Table to update Xpression --
CREATE TABLE SENTIMENT(
   id    INT  NOT NULL,
   sentiment varchar(25),
   created_on TIMESTAMP default current_timestamp
);
insert into SENTIMENT (id,sentiment) values (0,'upset');
insert into SENTIMENT (id,sentiment) values (1,'sad');
insert into SENTIMENT (id,sentiment) values (2,'neutral');
insert into SENTIMENT (id,sentiment) values (3,'happy');
insert into SENTIMENT (id,sentiment) values (4,'glad');


-- Table to update Xpression --
CREATE TABLE XPRESSION(
   id    SERIAL PRIMARY KEY  NOT NULL,
   tag_id BIGINT   NOT NULL references TAG(id),
   message VARCHAR(300),
   sentiment SMALLINT default 0,
   created_on TIMESTAMP default current_timestamp
);

-- Method to create access_code
Create or replace function access_code() returns text as
$$
declare
  chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
  result text := '';
  i integer := 0;
begin
  for i in 1..5 loop
    result := result || chars[1+random()*(array_length(chars, 1)-1)];
  end loop;
  return result;
end;
$$ language plpgsql;

CREATE TABLE QUESTION(
	id SERIAL PRIMARY KEY NOT NULL,
	question VARCHAR(300),
	likeCounter BIGINT default 0,
	event_id BIGINT NOT NULL REFERENCES event(id) ,
	created_on TIMESTAMP  default current_timestamp
);
CREATE TABLE EVENTAGENDA (
	id SERIAL PRIMARY KEY NOT NULL,
	agenda TEXT,
	start_time TIMESTAMP,
	end_time TIMESTAMP,
	event_id BIGINT NOT NULL REFERENCES event(id) ,
	created_on TIMESTAMP  default current_timestamp
);
