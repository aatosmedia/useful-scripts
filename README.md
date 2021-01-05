# Tietoa

Projekti sisältää joitakin valmiita skriptejä Linux-pohjaisen palvelimen hallintaan ja ohjelmien asentamiseen.

Sisältö on toteutettu alunperin usean wordpress asennuksen tekemistä varten opetuskäyttöön.

# Palvelimen asentaminen kuntoon

## Azure virtuaalikone

Esimerkissä käytetään virtuaalikonetta Microsoftin Azure pilvipalvelusta. Virtuaalikoneen pohjana on Bitnamin LAMP virtuaalikoneen kuva. Asenna virtuaalikone ensin seuraavan videon mukaisesti https://www.youtube.com/watch?v=ugbj3Z3FNcE

:warning: Pysähdy videossa kohtaan 7:50. Älä jatka tätä pidemmälle, koska videossa on vielä vanha ohjeistus ja sisältö on muuttunut sen jälkeen. Jatka alla olevien ohjeiden mukaan.

## Palvelimen valmistelu ja konfigurointi

**Seuraavat komennot tehdään palvelimella, joten yhdistä sinne videon mukaisesti.**

Komentojen edessä on `>` merkki. Sitä ei pidä käyttää komentojen kanssa vaan on vain auttamassa erottamaan komennot muista ohjeen sisällöistä.

```
# Tarkista, että olet kotikansiossa (/home/<tunnuksesi).
> pwd

# Lataa uusimmat skriptit palvelimelle. Eri versiot löydät osoitteesta https://github.com/nyluntu/useful-scripts/tags
# Kopioi tarvittaessa esimerkin komentoon uusin linkki zip-tiedstoon.
> wget https://github.com/nyluntu/useful-scripts/archive/v1.1.zip

# Purkaa ladatut tiedostot ja siirry kansioon. 
> unzip v1.0.zip
> cd useful-scripts-1.1

# Paketin mukana on useita skriptejä ja niille kuuluu antaa suoritusoikeudet tai niitä ei voi ajaa.
# Suoritusoikeudet voit varmistaa seuraavalla komennolla.
> chmod +x *.sh

# ls -lah komennolla voit tarvittaessa tarkistaa tiedostojen oikeudet. Tuloksen pitäisi näyttää suurinpiirtein
# seuraavanlaiselta.
#
# -rwxr-xr-x 1 sovelluskontti sovelluskontti 2.4K Jan  5 17:33 add-basic-auth.sh
# -rwxr-xr-x 1 sovelluskontti sovelluskontti 2.4K Jan  5 17:33 add-normal-user.sh
# -rwxr-xr-x 1 sovelluskontti sovelluskontti 6.7K Jan  5 17:33 add-wp-for-user.sh
# -rwxr-xr-x 1 sovelluskontti sovelluskontti 3.4K Jan  5 17:33 configure-server.sh
# -rwxr-xr-x 1 sovelluskontti sovelluskontti 2.5K Jan  5 17:33 manage-users.sh
# -rw-r--r-- 1 sovelluskontti sovelluskontti   82 Jan  5 17:33 template-users.csv
#
```

:heavy_exclamation_mark: Tarkista tässä vaiheessa, että palvelimen esimerkkisivu näkyy sen ip osoitteessa. `http://<palvelimen-ip-osoite>`

:warning: Seuraava komento tulee tehdä vain kerran. Sitä ei tarvitse enää uudellen tehdä. Vaikka komennon ajaisi uudelleen niin mikään ei välttämättä mene rikki mutta tätä ei ole täysin varmistettu.

Tarvitse myös bitnamin salasanan, joka virtuaalikoneen luonnin yhteydessä otettiin talteen. https://docs.bitnami.com/azure/faq/get-started/find-credentials/

```
# Tee tämä vain kerran.
> sudo ./configure-server.sh -p <bitnamin salasana>
```

Edellisen vaiheen komento muuttaa palvelimen asetuksia seuraavia vaiheita varten. Se asentaa myös tarvittavia lisäosia. Komento voi tulostaa paljon tekstiä mutta siitä ei tarvitse välittää.

Tässä vaiheessa voit vielä tarkistaa, että palvelimen sivu aukeaa selaimessa aikaisemmalla osoitteella. Bitnamin esimerkkisivun kuuluisi vielä näkyä.

## Wordpress asennusten tekeminen

Nyt edellisessä vaiheessa on valmisteltu kaikki tarpeellinen ja voidaan siirtyä luomaan palvelimen käyttäjät ja wordpress asennukset.

```
# Luo csv tiedosto luotaville käyttäjätileille ja asennuksille.
# Mukana on mallitiedosto, jota voit käyttää pohjana. Voit myös luoda itse 
# uuden haluamallasi nimellä.
> cp template-users.csv kayttajalista.csv

# Muokkaa sisältö haluamaksesi. Tärkeintä on, että csv tiedostossa on
# puolipisteellä (;) erotettuna kolme eri arvoa.
#
# myusername1;mypassword1;wp
#
# Jossa:
# - myusername1 on luotavan tilin käyttäjätunnus
# - mypassword1 on luotavan tilin salasana
# - wp tarkoittaa, että tilille luodaan myös valmis wordpress asennus. 

# Kun käyttäjälistasi on haluamasi näköinen niin jatka seuraavalla komennolla,
# joka viimeistelee asennukset.
sudo ./manage-users.sh -f kayttajalista.csv
```

Komennon ajaminen kestää hetken mutta lopputuloksena syntyy seuraavat asiat:

- Luodaan palvelimelle käyttäjätunnus.
- Luodaan käyttäjätunnukselle kotikansio /home/myusername1
- Luodaan käyttäjälle julkinen web -kansio /home/myusername1/public_html
- Suojataan julkinen web kansion .htpasswd suojauksella.
- Luodaan Wordpress asennus kansioon public_html/wp ja joka löytyy sitten selaimella osoitteesta http://<palvelimen-ip-osoite/~myusername1/wp
- public_html kansioon voidaan luoda vapaasti useampia kansioita tarpeen mukaan.
- Luodaan vielä käyttäjälle oma erillinen Mysql tietokanta: default_myusername1. Wordpress asennuksen tietokanta on luotu erikseen nimellä wp_myusername1, joten ne eivät sekoita toisiaan.

Tarkista, että verkkosivu näkyy osoiteissa:

- http://<palvelimen-ip-osoite/~myusername1/
- http://<palvelimen-ip-osoite/~myusername1/wp

## Käyttäjätunnukset ja salasanat

Kaikki käyttäjätunnukset ja salasanat on luotu edellisen vaiheen csv-tiedoston perusteella. Samat tunnukset ja salasanat käyvät seuraaviin kohtiin:

- Palvelimelle kirjautumiseen FTP tai SSH käyttäen.
- Wordpress ylläpitoon: http://<palvelimen-ip-osoite/~myusername1/wp/wp-admin
- .htpasswd suojauksessa on myös samat tunnukset.
- Mysql tietokantaa varten myös samat tunnukset toimivat.

# PHPMyAdmin

// TODO kirjoita tämä vielä puhtaaksi. Lyhyt ohje käyttämisestä: https://docs.bitnami.com/ibm/faq/get-started/access-ssh-tunnel/

# Muuta tärkeää

- Ei haittaa vaikka saman käyttäjälistan ajaa komennolla useamman kerran. Skripteissä on pyritty tarkistamaan, että jos käyttäjä tai jokin muu asennus löytyy jo niin silloin ei tehdä mikään. Näin vahingossa ei mitään yliajeta.
- Jos skripteihin tulee isompia muutoksia niin pyritään huolehtimaan ettei mitään vanhempaa tietoa häviä.
- Skriptit on jaettu pienempiin osiin, joita voi käyttää myös erikseen mutta tärkein on `manage-users.sh` joka käyttää muita skriptejä apuna.
- Jos tarvitset lisää tunnuksia niin tee uusi csv-tiedosto tai täydennä vanhan perään. Jossain tilanteessa on varmasti parempi pitää asiat omissa tiedostoissa. Tärkeää on, että samanniminen tunnus ei voi esiintyä missään kahteen kertaan.

